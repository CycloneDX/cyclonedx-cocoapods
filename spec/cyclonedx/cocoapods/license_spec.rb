# frozen_string_literal: true

#
# This file is part of CycloneDX CocoaPods
#
# Licensed under the Apache License, Version 2.0 (the “License”);
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0
# Copyright (c) OWASP Foundation. All Rights Reserved.
#

require 'rspec'
require 'cyclonedx/cocoapods/license'

RSpec.describe CycloneDX::CocoaPods::Pod::License do
  context 'when creating a new license' do
    context 'with an empty identifier' do
      it 'should raise an error' do
        expect { described_class.new(identifier: '    ') }.to raise_error(ArgumentError)
      end
    end

    context 'with an identifier included in the SPDX license list (regardless of case)' do
      it 'should create a license of type id' do
        existing_license_id = described_class::SPDX_LICENSES.sample
        mangled_case_id = existing_license_id.chars.map { |c| rand(2).zero? ? c.upcase : c.downcase }.join

        license = described_class.new(identifier: mangled_case_id)

        expect(license.identifier).to eq(existing_license_id)
        expect(license.identifier_type).to eq(:id)
      end
    end

    context 'with an identifier not included in the SPDX license list' do
      it 'should create a license of type name' do
        non_existing_license_id = 'custom-license-id'

        license = described_class.new(identifier: non_existing_license_id)

        expect(license.identifier).to eq(non_existing_license_id)
        expect(license.identifier_type).to eq(:name)
      end
    end
  end
end
