# frozen_string_literal: true

require 'spec_helper'

module Pronto
  # rubocop:disable Metrics/BlockLength
  describe Cppcheck do
    let(:cppcheck) { Cppcheck.new(patches) }
    let(:patches) { [] }
    describe '#executable' do
      subject(:executable) { cppcheck.executable }

      it 'is `cppcheck` by default' do
        expect(executable).to eql('cppcheck')
      end
    end

    describe 'parsing' do
      it 'filtering CPP files' do
        files = %w[
          test.py
          test.c test.c++ test.cc test.cu test.cuh test.icc
          test.g
          test.h++ test.hpp test.hxx test.hh test.cxx test.cpp
          test.rb
        ]

        exp = cppcheck.filter_cpp_files(files)
        expect(exp).to eq(%w[
                            test.c test.c++ test.cc test.cu test.cuh
                            test.icc test.h++ test.hpp test.hxx test.hh
                            test.cxx test.cpp
                          ])
      end

      it 'parses a linter output to a map' do
        # rubocop:disable Layout/LineLength
        executable_output = [
          "src/core/aio.c:546:20:style:variableScope:The scope of the variable 'rv' can be reduced.",
          "src/core/init.c:108:10:style:knownConditionTrueFalse:Condition 'init->i_once' is always false"
        ].join("\n")
        act = cppcheck.parse_output(executable_output)
        exp = [
          {
            file_path: 'src/core/aio.c',
            line_number: 546,
            column_number: 20,
            message: "cppcheck: variableScope:The scope of the variable 'rv' can be reduced.",
            level: 'warning'

          },
          {
            file_path: 'src/core/init.c',
            line_number: 108,
            column_number: 10,
            message: "cppcheck: knownConditionTrueFalse:Condition 'init->i_once' is always false",
            level: 'warning'
          }
        ]
        # rubocop:enable Layout/LineLength
        expect(act).to eq(exp)
      end
    end

    describe '#run' do
      around(:example) do |example|
        create_repository
        Dir.chdir(repository_dir) do
          example.run
        end
        delete_repository
      end

      let(:patches) { Pronto::Git::Repository.new(repository_dir).diff('main') }

      context 'patches are nil' do
        let(:patches) { nil }

        it 'returns an empty array' do
          expect(cppcheck.run).to eql([])
        end
      end

      context 'no patches' do
        let(:patches) { [] }

        it 'returns an empty array' do
          expect(cppcheck.run).to eql([])
        end
      end

      context 'with patch data' do
        before(:each) do
          function_use = <<-PASTFILE
          // nothing
          PASTFILE

          add_to_index('test.cpp', function_use)
          create_commit
        end

        context 'with error in changed file' do
          before(:each) do
            create_branch('staging', checkout: true)

            updated_function_def = <<-NEWFILE
            int foo(int b) { return b > 0 || b < 1; }
            NEWFILE

            add_to_index('best.cpp', updated_function_def)

            create_commit
            ENV['PRONTO_CPPCHECK_OPTS'] = ''
          end

          it 'returns correct error message' do
            run_output = cppcheck.run
            expect(run_output.count).to eql(2)
            expect(run_output[0].msg).to eql('cppcheck: incorrectLogicOperator:Logical disjunction always evaluates to true: b > 0 || b < 1.')
            expect(run_output[1].msg).to eql("cppcheck: unusedFunction:The function 'foo' is never used.")
          end
        end
      end
    end
  end
  # rubocop:enable Metrics/BlockLength
end
