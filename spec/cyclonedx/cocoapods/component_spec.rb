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
require 'cyclonedx/cocoapods/component'

RSpec.describe CycloneDX::CocoaPods::Component do
  context 'when creating new components' do
    let(:group) { 'application-group' }
    let(:name) { 'Application' }
    let(:version) { '1.3.5' }
    let(:type) { described_class::VALID_COMPONENT_TYPES.sample }

    context 'with an empty group' do
      it 'should raise an error' do
        expect do
          described_class.new(group: '    ', name: name, version: version,
                              type: type)
        end.to raise_error(ArgumentError, 'Group, if specified, must be non-empty')
      end
    end

    context 'with a nil name' do
      it 'should raise an error' do
        expect do
          described_class.new(name: nil, version: version, type: type)
        end.to raise_error(ArgumentError, 'Name must be non-empty')
      end
    end

    context 'with an empty name' do
      it 'should raise an error' do
        expect do
          described_class.new(name: '   ', version: version,
                              type: type)
        end.to raise_error(ArgumentError, 'Name must be non-empty')
      end
    end

    context 'with an invalid version' do
      it 'should raise an error' do
        expect do
          described_class.new(name: name, version: 'not-a-valid.version',
                              type: type)
        end.to raise_error(ArgumentError, /Malformed version number/)
      end
    end

    context 'with an invalid type' do
      it 'should raise an error' do
        expect do
          described_class.new(name: name, version: version,
                              type: 'invalid-type')
        end.to raise_error(ArgumentError, /is not valid component type/)
      end
    end

    context 'with valid values' do
      context 'without group' do
        it 'should properly build the component' do
          component = described_class.new(name: name, version: version, type: type)
          expect(component.group).to be_nil
          expect(component.name).to eq(name)
          expect(component.version).to eq(version)
          expect(component.type).to eq(type)
        end
      end

      context 'with group' do
        it 'should properly build the component' do
          component = described_class.new(group: group, name: name, version: version, type: type)
          expect(component.group).to eq(group)
          expect(component.name).to eq(name)
          expect(component.version).to eq(version)
          expect(component.type).to eq(type)
        end
      end
    end
  end
end
