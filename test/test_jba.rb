# encoding: Shift_JIS
require 'simplecov'
require 'test/unit'
SimpleCov.start

require 'jba'

class JbaTestCase < Test::Unit::TestCase
  def test_record
    obj = Jba::Record.new(1)
    assert_equal '1                                                                                                                       ', obj.dump
  end

  def test_wrong_record
    obj = Jba::Record.new(1)
    def obj.dump_record
      ''
    end
    assert_raise(Jba::IllegalStateError) do
      obj.dump
    end
  end

  def test_header_record
    obj = Jba::HeaderRecord.new
    obj.transfer_type = 21
    assert_equal '1210                                                                                                                    ', obj.dump
  end

  def test_error_number
    obj = Jba::HeaderRecord.new
    obj.transfer_type = nil
    assert_raise(ArgumentError) do
      obj.dump
    end
    obj.transfer_type = '1'
    assert_raise(ArgumentError) do
      obj.dump
    end
    obj.transfer_type = 123 # 2 digits
    assert_raise(ArgumentError) do
      obj.dump
    end
  end

  def test_error_character
    obj = Jba::TransferHeaderRecord.new
    obj.customer_code = 1
    obj.customer_name = nil
    assert_raise(ArgumentError) do
      obj.dump
    end
    obj.customer_name = 123
    assert_raise(ArgumentError) do
      obj.dump
    end
    obj.customer_name = 'ﾔﾏﾀﾞﾀﾛｳ'
    obj.transfer_mmdd = '0224'
    obj.bank_code = 3
    obj.bank_name = 'ﾔﾏﾀﾞ'
    obj.branch_code = 4
    obj.branch_name = 'ﾀﾛｳ'
    obj.account_type = 1
    obj.account_number = 5
    obj.dump # OK
    obj.customer_name = 'ﾔﾏﾀﾞﾀﾛｳﾔﾏﾀﾞﾀﾛｳﾔﾏﾀﾞﾀﾛｳﾔﾏﾀﾞﾀﾛｳﾔﾏﾀﾞﾀﾛｳﾔﾏﾀﾞﾀﾛ'
    assert_raise(ArgumentError) do
      obj.dump
    end
  end

  def test_transfer_header_record
    obj = Jba::TransferHeaderRecord.new
    obj.customer_code = 1
    obj.customer_name = 'ﾔﾏﾀﾞﾀﾛｳ'
    obj.transfer_mmdd = '0224'
    obj.bank_code = 3
    obj.bank_name = 'ﾔﾏﾀﾞ'
    obj.branch_code = 4
    obj.branch_name = 'ﾀﾛｳ'
    obj.account_type = 1
    obj.account_number = 5
    assert_equal '12100000000001ﾔﾏﾀﾞﾀﾛｳ                                 02240003ﾔﾏﾀﾞ           004ﾀﾛｳ            10000005                 ', obj.dump
  end

  def test_general_transfer_data_record
    obj = Jba::GeneralTransferDataRecord.new
    obj.bank_code = 1
    obj.bank_name = 'ﾔﾏﾀﾞ'
    obj.branch_code = 2
    obj.branch_name = 'ﾀﾛｳ'
    obj.clearinghouse_code = 3
    obj.account_type = 4
    obj.account_number = 5
    obj.recipient = 'ﾔﾏﾀﾞﾀﾛｳ'
    obj.amount = 6
    obj.operation_type = 0
    obj.recipient_data_1 = '7'
    obj.recipient_data_2 = '8'
    obj.transaction_type = 7
    obj.recipient_data_type = 'D'
    assert_equal '20001ﾔﾏﾀﾞ           002ﾀﾛｳ            000340000005ﾔﾏﾀﾞﾀﾛｳ                       000000000607         8         7D       ', obj.dump
  end

  def test_transfer_trailer_record
    obj = Jba::TransferTrailerRecord.new
    obj.total_data_records = 1
    obj.total_amount = 2
    assert_equal '8000001000000000002                                                                                                     ', obj.dump
  end

  def test_end_record
    obj = Jba::EndRecord.new
    assert_equal '9                                                                                                                       ', obj.dump
  end

  def test_generatl_transfer
    obj = Jba::GeneralTransfer.new(
      :customer_code => 1,
      :customer_name => '2',
      :transfer_mmdd => '0224',
      :bank_code => 3,
      :branch_code => 4,
      :account_type => 1,
      :account_number => 5
    )
    # empty data
    assert_equal "121000000000012                                       02240003               004               10000005                 \r\n" +
                 "8000000000000000000                                                                                                     \r\n" +
                 "9                                                                                                                       \r\n", obj.dump
    # EOF
    assert_equal "121000000000012                                       02240003               004               10000005                 \r\n" +
                 "8000000000000000000                                                                                                     \r\n" +
                 "9                                                                                                                       \r\n\x1A", obj.dump(:eof => true)
    assert_equal "121000000000012                                       02240003               004               10000005                 \r\n" +
                 "8000000000000000000                                                                                                     \r\n" +
                 "9                                                                                                                       \r\n", obj.dump(:eof => false)
    assert_equal "121000000000012                                       02240003               004               10000005                 \r\n" +
                 "8000000000000000000                                                                                                     \r\n" +
                 "9                                                                                                                       \r\n", obj.dump


    # initial record
    obj.add(
      :bank_code => 1,
      :branch_code => 2,
      :account_type => 4,
      :account_number => 3,
      :recipient => '5',
      :amount => 6,
      :operation_type => 0,
      :transaction_type => 7,
    )
    assert_equal "121000000000012                                       02240003               004               10000005                 \r\n" +
                 "20001               002               0000400000035                             00000000060                    7        \r\n" +
                 "8000001000000000006                                                                                                     \r\n" +
                 "9                                                                                                                       \r\n", obj.dump

    # same record
    obj.add(
      :bank_code => 1,
      :branch_code => 2,
      :account_type => 4,
      :account_number => 3,
      :recipient => '5',
      :amount => 6,
      :operation_type => 0,
      :transaction_type => 7,
    )
    assert_equal "121000000000012                                       02240003               004               10000005                 \r\n" +
                 "20001               002               0000400000035                             00000000060                    7        \r\n" +
                 "20001               002               0000400000035                             00000000060                    7        \r\n" +
                 "8000002000000000012                                                                                                     \r\n" +
                 "9                                                                                                                       \r\n", obj.dump

    # another record
    obj.add(
      :bank_code => 1,
      :bank_name => 'ｼﾞｸ',
      :branch_code => 2,
      :branch_name => 'ｼﾝｼﾞﾕｸ',
      :clearinghouse_code => '1234',
      :account_type => 4,
      :account_number => 3,
      :recipient => '5',
      :amount => 80315,
      :operation_type => 0,
      :recipient_data_1 => 'ABC',
      :recipient_data_2 => 'DEF',
      :transaction_type => 7,
      :recipient_data_type => 'X',
    )
    assert_equal "121000000000012                                       02240003               004               10000005                 \r\n" +
                 "20001               002               0000400000035                             00000000060                    7        \r\n" +
                 "20001               002               0000400000035                             00000000060                    7        \r\n" +
                 "20001ｼﾞｸ            002ｼﾝｼﾞﾕｸ         1234400000035                             00000803150ABC       DEF       7X       \r\n" +
                 "8000003000000080327                                                                                                     \r\n" +
                 "9                                                                                                                       \r\n", obj.dump
  end
end
