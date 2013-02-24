# Jba

JBA file format handler

## Installation

For now it only can generate 'General Transfer' file.

    gem 'jba'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install jba

## Usage

    obj = Jba::GeneralTransfer.new(
      :customer_code => 123,
      :customer_name => 'My Company',
      :transfer_mmdd => Time.now.strftime("%m%d"),
      :bank_code => 1,
      :branch_code => 123,
      :account_type => 1,
      :account_number => 1234567,
    )
    obj.add(
      :bank_code => 1,
      :branch_code => 123,
      :account_type => 1,
      :account_number => 2345678,
      :recipient => 'Hiroshi Nakamura',
      :amount => 80315,
      :operation_type => 0,
      :transaction_type => 7,
    )
    puts obj.dump

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
