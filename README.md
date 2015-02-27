# csv_configuration_guesser

A library for guessing the csv configuration from his content.

## Usage

A simple usage example:

    import 'package:csv_configuration_guesser/csv_configuration_guesser.dart';

    main() {
      String content = '''
    id,value1,value2,description
    0,1,10,"sensor1"
    0,2,20,"sensor2"
    0,1,30,"sensor1"
    ''';
      CSVConfigurationGuesser guesser = new CSVConfigurationGuesser();
      CSVConfiguration configuration = guesser.guess(content);
      print('newLine: ${configuration.newLine}');
      print('delimiter: ${configuration.delimiter}');
      print('quote: ${configuration.quote}');
    }

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/fedy2/csv_configuration_guesser/issues

