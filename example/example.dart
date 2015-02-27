// Copyright (c) 2015, Federico De Faveri. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library csv_configuration_guesser.example;

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
