# encoding: Shift_JIS
require 'jba/version'

module Jba
  CRLF = "\r\n"
  SP = ' '
  ZERO = '0'
  EOF = "\x1a"

  class IllegalStateError < StandardError
  end

  # JBA Record - �S�⋦�t�@�C�����C�A�E�g���R�[�h
  class Record
    attr_accessor :data_type # 1 �f�[�^�敪 N(1) 1�F�w�b�_�[�A2: �f�[�^�A8: �g���[���A9: �G���h

    def initialize(data_type = nil)
      @data_type = data_type
    end

    # Returns 120 chars of String
    def dump
      record = format_N(:data_type, 1) +
        dump_record
      if record.bytesize != 120
        raise IllegalStateError, "record size #{record.bytesize} != 120"
      end
      record
    end

  private

    def dump_record
      SP * 119
    end

    def format_N(name, size)
      value = instance_variable_get("@#{name}")
      if value.nil?
        raise ArgumentError, "value not set for #{name}"
      end
      if value.is_a?(Integer)
        data = sprintf("%0#{size}d", value)
      elsif value.to_s.bytesize == size
        data = value
      else
        raise ArgumentError, "value #{value} for #{name} is not an Integer"
      end
      if data.bytesize != size
        raise ArgumentError, "data '#{data}' (#{data.bytesize} digits) is too big for #{name} (#{size} digits)"
      end
      data
    end

    def format_C(name, size)
      value = instance_variable_get("@#{name}")
      if value.nil?
        raise ArgumentError, "value not set for #{name}"
      end
      unless value.is_a?(String)
        raise ArgumentError, "value #{value} for #{name} is not a String"
      end
      data = sprintf("%-#{size}s", value)
      if data.bytesize != size
        raise ArgumentError, "data '#{data}' (#{data.bytesize} bytes) is too big for #{name} (#{size} bytes)"
      end
      data
    end
  end

  # JBA Header Record - �S�⋦�w�b�_���R�[�h
  # 1 �f�[�^�敪 - N(1) 1�F�w�b�_�[���R�[�h
  class HeaderRecord < Record
    attr_accessor :transfer_type  # 2 ��ʃR�[�h           N(2) 21�F�����U��
    attr_accessor :encoding_type  # 3 �R�[�h�敪           N(1) 0�FJIS

    def initialize
      super
      @data_type = 1
      @transfer_type = nil
      @encoding_type = 0
    end

  private

    def dump_record
      format_N(:transfer_type, 2) +
        format_N(:encoding_type, 1) +
        dump_header_record
    end

    def dump_header_record
      SP * 116
    end
  end

  # JBA transfer Header Record - �S�⋦�U���w�b�_���R�[�h
  class TransferHeaderRecord < HeaderRecord
    attr_accessor :customer_code  # 4 �U���˗��l�R�[�h     N(10)
    attr_accessor :customer_name  # 5 �U���˗��l���i�J�i�j C(40)
    attr_accessor :transfer_mmdd  # 6 �U����               N(4) mmdd�i�����j Time#strftime("%m%d") in Ruby
    attr_accessor :bank_code      # 7 ��s�R�[�h           N(4)
    attr_accessor :bank_name      # 8 ��s���i�J�i�j       C(15) optional
    attr_accessor :branch_code    # 9 �x�X�R�[�h           N(3)
    attr_accessor :branch_name    # 10 �x�X���i�J�i�j      C(15) optional
    attr_accessor :account_type   # 11 �Ȗ�                N(1) 1�F���ʁ@2�F�����@9�F���̑�
    attr_accessor :account_number # 12 �����ԍ�            N(7)
    attr_accessor :dummy          # 13 �_�~�[              C(17)

    def initialize
      super
      @transfer_type = 21
      @customer_code = nil
      @customer_name = nil
      @transfer_mmdd = nil
      @bank_code = nil
      @bank_name = SP * 15
      @branch_code = nil
      @branch_name = SP * 15
      @account_type = nil
      @account_number = nil
      @dummy = SP * 17
    end

  private

    def dump_header_record
      format_N(:customer_code, 10) +
        format_C(:customer_name, 40) +
        format_C(:transfer_mmdd, 4) + # intentionally: treat mmdd as C
        format_N(:bank_code, 4) +
        format_C(:bank_name, 15) +
        format_N(:branch_code, 3) +
        format_C(:branch_name, 15) +
        format_N(:account_type, 1) +
        format_N(:account_number, 7) +
        format_C(:dummy, 17)
    end
  end

  # JBA transfer Data Record - �S�⋦�u�����U���v�f�[�^���R�[�h
  class GeneralTransferDataRecord < Record
    attr_accessor :bank_code           # 2 ��s�R�[�h       N(4)
    attr_accessor :bank_name           # 3 ��s���i�J�i�j   C(15) optional
    attr_accessor :branch_code         # 4 �x�X�R�[�h       N(3)
    attr_accessor :branch_name         # 5 �x�X���i�J�i�j   C(15) optional
    attr_accessor :clearinghouse_code  # 6 ��`�������ԍ�   N(4) optional
    attr_accessor :account_type        # 7 �Ȗ�             N(1) 1�F���ʁ@2�F�����@4�F���~�@9�F���̑�
    attr_accessor :account_number      # 8 �����ԍ�         N(7)
    attr_accessor :recipient           # 9 ���l���i�J�i�j C(30)
    attr_accessor :amount              # 10 �U�����z        N(10)
    attr_accessor :operation_type      # 11 �V�K�R�[�h      N(1) 0�F���̑��i1�F��1 ��U�����A2�F�ύX���j
    attr_accessor :recipient_data_1    # 12 �ڋq�R�[�h1     N/C(10) optional
    attr_accessor :recipient_data_2    # 13 �ڋq�R�[�h2     N/C(10) optional
    attr_accessor :transaction_type    # 14 �U���w��敪    N(1) 7�F�d�M���@8�F������
    attr_accessor :recipient_data_type # 15 ���ʃR�[�h      C(1) optional
    attr_accessor :dummy               # 16 �_�~�[          C(7)

    def initialize
      super
      @data_type = 2
      @bank_code = nil
      @bank_name = SP * 15
      @branch_code = nil
      @branch_name = SP * 15
      @clearinghouse_code = 0
      @account_type = nil
      @account_number = nil
      @recipient = nil
      @ammount = nil
      @operation_type = nil
      @recipient_data_1 = SP * 10
      @recipient_data_2 = SP * 10
      @transaction_type = nil
      @recipient_data_type = SP
      @dummy = SP * 7
    end

  private

    def dump_record
      format_N(:bank_code, 4) +
        format_C(:bank_name, 15) +
        format_N(:branch_code, 3) +
        format_C(:branch_name, 15) +
        format_N(:clearinghouse_code, 4) +
        format_N(:account_type, 1) +
        format_N(:account_number, 7) +
        format_C(:recipient, 30) +
        format_N(:amount, 10) +
        format_N(:operation_type, 1) +
        format_C(:recipient_data_1, 10) +
        format_C(:recipient_data_2, 10) +
        format_N(:transaction_type, 1) +
        format_C(:recipient_data_type, 1) +
        format_C(:dummy, 7)
    end
  end

  # JBA transfer Trailer Record - �S�⋦�U���g���[�����R�[�h
  class TransferTrailerRecord < Record
    attr_accessor :total_data_records # 2 ���v����   N(6)
    attr_accessor :total_amount       # 3 ���v���z   N(12)
    attr_accessor :dummy              # 4 �_�~�[     C(101)

    def initialize
      super
      @data_type = 8
      @total_data_records = 0
      @total_amount = 0
      @dummy = SP * 101
    end

  private

    def dump_record
      format_N(:total_data_records, 6) +
        format_N(:total_amount, 12) + 
        format_C(:dummy, 101)
    end
  end

  # JBA End Record - �S�⋦�G���h���R�[�h
  class EndRecord < Record
    attr_accessor :dummy   # 2 �_�~�[     C(119)

    def initialize
      super
      @data_type = 9
      @dummy = SP * 119
    end

  private

    def dump_record
      format_C(:dummy, 119)
    end
  end

  class GeneralTransfer
    attr_reader :header
    attr_reader :records
    attr_reader :trailer

    def initialize(hash = {})
      @header = TransferHeaderRecord.new
      @records = []
      @trailer = TransferTrailerRecord.new
      inject_hash(@header, hash)
    end

    def add(hash = {})
      data = GeneralTransferDataRecord.new
      inject_hash(data, hash)
      @records << data
      @trailer.total_data_records += 1
      @trailer.total_amount += data.amount.to_i
    end

    def dump
      @header.dump + CRLF +
        @records.map { |data|
          data.dump + CRLF
        }.join +
        @trailer.dump + CRLF + EOF # EOF could be optional
    end

  private

    def inject_hash(obj, hash)
      hash.each do |key, value|
        obj.send(key.to_s + '=', value)
      end
    end
  end
end
