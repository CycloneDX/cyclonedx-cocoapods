# frozen_string_literal: true

require 'optparse'
require 'logger'
require 'cocoapods'

require_relative 'pod'
require_relative 'bom_builder'
require_relative 'search_engine'

module CycloneDX
  module CocoaPods
    class PodfileParsingError < StandardError; end
    class BOMOutputError < StandardError; end

    class CLIRunner
      def run
        begin
          setup_logger # Needed in case we have errors while processing CLI parameters
          options = parseOptions
          setup_logger(verbose: options[:verbose])
          @logger.debug "Running cyclonedx-cocoapods with options: #{options}"

          ensure_podfile_and_lock_are_present(options)
          pods = parse_pod_file(options)
          search_engine = SearchEngine.new(source_manager: create_source_manager(options))

          populate_pods_with_additional_info(pods, search_engine)

          bom = BOMBuilder.new(pods: pods).bom(version: options[:version] || 1)
          write_bom_to_file(bom: bom, options: options)
        rescue StandardError => e
          @logger.error e.message
          exit 1
        end
      end


      private

      def parseOptions
        parsedOptions = {}
        OptionParser.new do |options|
          options.banner = 'Usage: cyclonedx-cocoapods [options]'

          options.on('--[no-]verbose', 'Run verbosely') do |v|
            parsedOptions[:verbose] = v
          end
          options.on('-p', '--path path', '(Optional) Path to CocoaPods project directory, current directory if missing') do |path|
            parsedOptions[:path] = path
          end
          options.on('-o', '--output bom_file_path', '(Optional) Path to output the bom.xml file to') do |bom_file_path|
            parsedOptions[:bom_file_path] = bom_file_path
          end
          options.on('-vversion', '--version version', Integer, '(Optional) Version of the generated BOM, 1 if not provided') do |version|
            parsedOptions[:version] = version
          end
          options.on_tail('-h', '--help', 'Show help message') do
            puts options
            exit
          end
        end.parse!
        return parsedOptions
      end


      def setup_logger(verbose: true)
        @logger ||= Logger.new($stdout)
        @logger.level = verbose ? Logger::DEBUG : Logger::INFO
      end


      def ensure_podfile_and_lock_are_present(options)
        project_dir = Pathname.new(options[:path] || Dir.pwd)
        raise PodfileParsingError, "#{options[:path]} is not a valid directory." unless File.directory?(project_dir)
        options[:podfile_path] = project_dir + 'Podfile'
        raise PodfileParsingError, "Missing Podfile in #{project_dir}. Please use the --path option if not running from the CocoaPods project directory." unless File.exist?(options[:podfile_path])
        options[:podfile_lock_path] = project_dir + 'Podfile.lock'
        raise PodfileParsingError, "Missing Podfile.lock, please run pod install before generating BOM" unless File.exist?(options[:podfile_lock_path])
      end


      def parse_pod_file(options)
        @logger.debug "Parsing pods from #{options[:podfile_lock_path]}"
        lockfile = ::Pod::Lockfile.from_file(options[:podfile_lock_path])
        @logger.debug "Pods successfully parsed"
        return lockfile.pods_by_spec_repo.values.flatten.map { |name| Pod.new(name: name, version: lockfile.version(name)) }
      end


      def create_source_manager(options)
        sourceManager = ::Pod::Source::Manager.new('~/.cocoapods/repos') # TODO: Can we use CocoaPods configuration somehow?
        @logger.debug "Parsing sources from #{options[:podfile_path]}"
        podfile = ::Pod::Podfile.from_file(options[:podfile_path])
        podfile.sources.each do |source|
          @logger.debug "Ensuring #{source} is available for searches"
          sourceManager.find_or_create_source_with_url(source)
        end
        @logger.debug "Source manager successfully created with all needed sources"
        return sourceManager
      end


      def populate_pods_with_additional_info(pods, search_engine)
        pods.each do |pod|
          @logger.debug "Completing information for #{pod.name}"
          pod.populate(search_engine.attributes_for(pod: pod))
        end
        return pods
      end


      def write_bom_to_file(bom:, options:)
        bom_file_path = Pathname.new(options[:bom_file_path] || './bom.xml').expand_path
        bom_dir = bom_file_path.dirname

        begin
          FileUtils.mkdir_p(bom_dir) unless bom_dir.directory?
        rescue
          raise BOMOutputError, "Unable to create the BOM output directory at #{bom_dir}"
        end

        begin
          File.open(bom_file_path, 'w') { |file| file.write(bom) }
          @logger.info "BOM written to #{bom_file_path}"
        rescue
          raise BOMOutputError, "Unable to write the BOM to #{bom_file_path}"
        end
      end
    end
  end
end
