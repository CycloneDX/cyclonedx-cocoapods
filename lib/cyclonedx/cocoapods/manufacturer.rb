# frozen_string_literal: true

#
# This file is part of CycloneDX CocoaPods
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0
# Copyright (c) OWASP Foundation. All Rights Reserved.
#

module CycloneDX
  module CocoaPods
    class Manufacturer
      attr_reader :name, :url, :contact_name, :email, :phone

      def initialize(name: nil, url: nil, contact_name: nil, email: nil, phone: nil)
        raise ArgumentError, 'Name must be non empty' if name.nil? || name.to_s.strip.empty?

        if !name.nil? && name.to_s.strip.empty?
          raise ArgumentError, 'name, if specified, must be non empty'
        end

        if !url.nil? && url.to_s.strip.empty?
          raise ArgumentError, 'URL, if specified, must be non empty'
        end

        if !contact_name.nil? && contact_name.to_s.strip.empty?
          raise ArgumentError, 'Contact name, if specified, must be non empty'
        end

        if !email.nil? && email.to_s.strip.empty?
          raise ArgumentError, 'Email, if specified, must be non empty'
        end

        if !phone.nil? && phone.to_s.strip.empty?
          raise ArgumentError, 'Phone, if specified, must be non empty'
        end

        @name = name
        @url = url
        @contact_name = contact_name
        @email = email
        @phone = phone
      end
    end
  end
end
