# frozen_string_literal: true

require 'pronto'
require 'shellwords'
require 'open3'

module Pronto
  # Main class for extracting cppcheck complains
  class Cppcheck < Runner
    C_OR_CPP_FILE_EXTENSIONS = %w[c c++ cc cu cuh icc h++ hpp hxx hh cxx cpp].freeze

    def initialize(patches, commit = nil)
      super(patches, commit)
    end

    def executable
      'cppcheck'
    end

    def files
      return [] if @patches.nil?

      @files ||= @patches
                 .select { |patch| patch.additions.positive? }
                 .map(&:new_file_full_path)
                 .map(&:to_s)
                 .compact
    end

    def patch_line_for_offence(path, lineno)
      patch_node = @patches.find do |patch|
        patch.new_file_full_path.to_s == path
      end

      return if patch_node.nil?

      patch_node.added_lines.find do |patch_line|
        patch_line.new_lineno == lineno
      end
    end

    def run
      if files.any?
        messages(run_cppcheck)
      else
        []
      end
    end

    def run_cppcheck # rubocop:disable Metrics/MethodLength
      Dir.chdir(git_repo_path) do
        cpp_files = filter_cpp_files(files)
        files_to_lint = cpp_files.join(' ')
        extra = ENV.fetch('PRONTO_CPPCHECK_OPTS', nil)
        if files_to_lint.empty?
          []
        else
          cmd = "#{executable} --template='{file}:{line}:{column}:{severity}:{id}:{message}' --quiet #{extra} #{files_to_lint}"
          _stdout, stderr, _status = Open3.capture3(cmd)
          return [] if stderr.nil?

          parse_output stderr
        end
      end
    end

    def c_or_cpp?(file)
      C_OR_CPP_FILE_EXTENSIONS.any? { |extension| file.end_with? ".#{extension}" }
    end

    def filter_cpp_files(all_files)
      all_files.select { |file| c_or_cpp? file.to_s }
               .map { |file| file.to_s.shellescape }
    end

    def parse_output(executable_output)
      lines = executable_output.split("\n")
      lines.map { |line| parse_output_line(line) }
    end

    def parse_output_line(line)
      splits = line.strip.split(':')
      message = splits[4..].join(':').strip
      message = "cppcheck: #{message}"

      {
        file_path: splits[0],
        line_number: splits[1].to_i,
        column_number: splits[2].to_i,
        message:,
        level: violation_level(splits[3])
      }
    end

    def violation_level(severity)
      # TODO
      if severity == 'error'
        'error'
      else
        'warning'
      end
    end

    def messages(complains)
      complains.map do |msg|
        patch_line = patch_line_for_offence(msg[:file_path],
                                            msg[:line_number])
        next if patch_line.nil?

        description = msg[:message]
        path = patch_line.patch.delta.new_file[:path]
        Message.new(path, patch_line, msg[:level].to_sym,
                    description, nil, self.class)
      end.compact
    end

    def git_repo_path
      @git_repo_path ||= Rugged::Repository.discover(File.expand_path(Dir.pwd))
                                           .workdir
    end
  end
end
