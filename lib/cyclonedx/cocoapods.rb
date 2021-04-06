# frozen_string_literal: true

require 'optparse'
require 'logger'
require 'cocoapods-core'

require_relative 'cocoapods/version'
require_relative 'pod'
require_relative 'bom_builder'

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

          # We get pods categorized by spec repo because we'll need this information when we search for the pod
          pods_by_spec_repo = parse_pod_file(options)

          pods = pods_by_spec_repo.values.flatten    # We just flatten now, we will have to complete pod information later

          bom = BOMBuilder.new(pods: pods).bom(version: options[:version] || 1)
          write_bom_to_file(bom: bom, options: options)
        rescue StandardError => e
          @logger.error e.message
          abort
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


      def parse_pod_file(options)
        project_dir = Pathname.new(options[:path] || Dir.pwd)
        raise PodfileParsingError, "#{options[:path]} is not a valid directory." unless File.directory?(project_dir)
        podfile_path = project_dir + 'Podfile'
        raise PodfileParsingError, "Missing Podfile in #{project_dir}. Please use the --path option if not running from the CocoaPods project directory." unless File.exist?(podfile_path)
        podfile_lock_path = project_dir + 'Podfile.lock'
        raise PodfileParsingError, "Missing Podfile.lock, please run pod install before generating BOM" unless File.exist?(podfile_lock_path)

        @logger.debug "Parsing pods from #{podfile_lock_path}"
        lockfile = ::Pod::Lockfile.from_file(podfile_lock_path)
        @logger.debug "Pods successfully parsed."
        return lockfile.pods_by_spec_repo.transform_values { |pod_names| pod_names.map { |name| Pod.new(name: name, version: lockfile.version(name)) } }
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
