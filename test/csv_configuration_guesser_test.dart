// Copyright (c) 2015, Federico De Faveri. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library csv_configuration_guesser_test;

import 'dart:math';
import 'package:csv_configuration_guesser/csv_configuration_guesser.dart';
import 'package:unittest/unittest.dart';

void main() => defineTests();

void defineTests() {

  group('guess tests', () {

    CSVConfigurationGuesser guesser;
    setUp(() {
      guesser = new CSVConfigurationGuesser();
    });

    CSVConfigurationGuesser.DEFAULT_NEW_LINES.forEach((String newLine) {
      test('guessNewLine ${newLine.codeUnits}', () {
        String content = generateContent(newLine: newLine, numberOfRows: 12);
        expect(guesser.guessNewLine(content), newLine);
      });
    });

    test('guessDelimiterBySd', () {
      Map sds = {
        code('a'): 0,
        code('b'): 10,
        code(','): 0.1,
        code(':'): 0.2
      };
      expect(guesser.guessDelimiterBySd(sds), ",");
    });

    test('guessQuote', () {
      List<String> rows = ["\"ab'c\",\"d'ef\"", "\"g'hj\",\"l'kj\""];
      expect(guesser.guessQuote(rows), '"');
    });

    test('guess', () {

      CSVConfigurationGuesser.DEFAULT_NEW_LINES.forEach((String newLine) {
        CSVConfigurationGuesser.DEFAULT_QUOTES.forEach((String quote) {
          CSVConfigurationGuesser.DEFAULT_DELIMITERS.forEach((String delimiter) {
            String content = generateContent(newLine: newLine, quote: quote, delimiter: delimiter);
            CSVConfiguration configuration = guesser.guess(content);
            expect(configuration.newLine, newLine);
            expect(configuration.quote, quote);
            expect(configuration.delimiter, delimiter);
          });

        });
      });
    });

  });

  group('utility tests', () {
    CSVConfigurationGuesser guesser;
    setUp(() {
      guesser = new CSVConfigurationGuesser();
    });

    test('merge', () {
      Map<int, int> source = {
        1: 0,
        2: 2,
        3: 3
      };
      Map<int, int> target = {
        1: 1,
        2: 0,
        4: 4
      };
      guesser.merge(source, target);
      expect(target, {
        1: 1,
        2: 2,
        3: 3,
        4: 4
      });
    });

    test('avgs', () {
      Map<int, int> counts = {
        1: 0,
        2: 2,
        3: 3
      };
      expect(guesser.avgs(counts, 2), {
        1: 0,
        2: 1,
        3: 1.5
      });
    });

    test('mergeSd', () {
      Map<int, int> source = {
        1: 0,
        2: 2,
        3: 3
      };
      Map<int, double> target = {
        1: 0,
        2: 1,
        4: 4
      };
      guesser.mergeSd(source, target);
      expect(target, {
        1: 0,
        2: 5,
        3: 9,
        4: 4
      });
    });


  });

  group('rowCounts', () {
    CSVConfigurationGuesser guesser;
    setUp(() {
      guesser = new CSVConfigurationGuesser();
    });

    test('rowCounts no quote', () {
      String row = "aabbc";
      expect(guesser.rowCounts(row), {
        code('a'): 2,
        code('b'): 2,
        code('c'): 1
      });
    });

    test('rowCounts with quote', () {
      String row = "aa\"bb\"bc";
      expect(guesser.rowCounts(row, code('"')), {
        code('a'): 2,
        code('b'): 1,
        code('c'): 1
      });
    });
  });

  group('rowsStatistics', () {
    CSVConfigurationGuesser guesser;
    setUp(() {
      guesser = new CSVConfigurationGuesser();
    });


    test('rowsStatistics no quote', () {
      List<String> rows = ["abc", "ab", "ad"];
      Map statistics = guesser.rowsStatistics(rows);
      expect(statistics["counts"], {
        code('a'): 3,
        code('b'): 2,
        code('c'): 1,
        code('d'): 1
      });

      expect(statistics["avgs"], {
        code('a'): 3 / 3,
        code('b'): 2 / 3,
        code('c'): 1 / 3,
        code('d'): 1 / 3
      });

      expect(statistics["sds"], {
        code('a'): 3 - 3 * pow(3 / 3, 2),
        code('b'): 2 - 3 * pow(2 / 3, 2),
        code('c'): 1 - 3 * pow(1 / 3, 2),
        code('d'): 1 - 3 * pow(1 / 3, 2)
      });
    });

    test('rowsStatistics with quote', () {
      List<String> rows = ["a\"b\"c", "a\"b\"", "abd"];
      Map statistics = guesser.rowsStatistics(rows, '"');
      expect(statistics["counts"], {
        code('a'): 3,
        code('b'): 1,
        code('c'): 1,
        code('d'): 1
      });

      expect(statistics["avgs"], {
        code('a'): 3 / 3,
        code('b'): 1 / 3,
        code('c'): 1 / 3,
        code('d'): 1 / 3
      });

      expect(statistics["sds"], {
        code('a'): 3 - 3 * pow(3 / 3, 2),
        code('b'): 1 - 3 * pow(1 / 3, 2),
        code('c'): 1 - 3 * pow(1 / 3, 2),
        code('d'): 1 - 3 * pow(1 / 3, 2)
      });
    });
  });

}

String generateContent({String newLine: '\n', String quote: '"', String delimiter: ',', List<String> header: const ["id", "timestamp", "value", "source", "comment"], List<Type> typeOfColumns: const [int, DateTime, double, String, String], int numberOfRows: 10}) {

  if (header != null && header.length != typeOfColumns.length) throw new Exception("Headers cardinality differs from type of columns cardinality");

  StringBuffer content = new StringBuffer();

  if (header != null) content.write(buildRow(header, quote, delimiter));
  content.write(newLine);

  for (int i = 0; i < numberOfRows; i++) {
    List row = generateRow(typeOfColumns);
    content.write(buildRow(row, quote, delimiter));
    if (i < numberOfRows - 1) content.write(newLine);
  }

  return content.toString();
}

Random random = new Random();

List generateRow(List<Type> types) {
  List values = [];
  types.forEach((Type type) {
    if (type == int) values.add(random.nextInt(1000));
    if (type == double) values.add(random.nextDouble());
    if (type == String) values.add(randomString(30));
    if (type == DateTime) values.add(randomDate());
  });
  return values;
}

DateTime randomDate() {
  return new DateTime(random.nextInt(2050), (1 + random.nextInt(12)), 1 + random.nextInt(28));
}

String randomString(int length) {
  StringBuffer string = new StringBuffer();
  int start = code('A');
  int end = code('z');
  for (int i = 0; i < length; i++) string.writeCharCode(start + random.nextInt(end - start));
  return string.toString();
}

String buildRow(List values, String quote, String delimiter) {
  StringBuffer row = new StringBuffer();
  bool first = true;
  values.forEach((var value) {
    if (first) first = false;
    else row.write(delimiter);
    
    if (value is num) row.write("$value");
    if (value is String || value is DateTime) {
      String s = "$value".replaceAll(quote, quote + quote);
      row.write("$quote$s$quote");
    }
  });

  return row.toString();
}
