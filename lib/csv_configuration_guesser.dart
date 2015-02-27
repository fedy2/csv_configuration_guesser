// Copyright (c) 2015, Federico De Faveri. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// The csv_configuration_guesser library.
library csv_configuration_guesser;

import 'dart:math';

class CSVConfigurationGuesser {

  static const String LF = '\u{000A}';
  static const String CR = '\u{000D}';
  static const String LF_CR = "$LF$CR";

  static const List<String> DEFAULT_NEW_LINES = const [LF, CR, LF_CR];

  static const String QUOTATION_MARK = '\u{0022}';
  static const String APOSTROPHE = '\u{0027}';

  static const List<String> DEFAULT_QUOTES = const [QUOTATION_MARK, APOSTROPHE];

  static const String COMMA = ",";
  static const String TAB = "\t";
  static const String SPACE = " ";
  static const String COLON = ":";
  static const String SEMICOLON = ";";

  static const List<String> DEFAULT_DELIMITERS = const [COMMA, TAB, SPACE, COLON, SEMICOLON];


  CSVConfiguration guess(String content) {

    CSVConfiguration configuration = new CSVConfiguration();

    configuration.newLine = guessNewLine(content);
    
    List<String> rows = getRows(content, configuration.newLine);
    
    configuration.quote = guessQuote(rows);
    
    configuration.delimiter = guessDelimiter(rows, configuration.quote);

    return configuration;
  }
  
  List<String> getRows(String content, String newLine) => content.split(newLine);
  
  String guessDelimiter(List<String> rows, [String quote, List<String> candidates = DEFAULT_DELIMITERS]) {
    Map statistics = rowsStatistics(rows, quote);
    return guessDelimiterBySd(statistics["sds"], candidates);
  }

  String guessDelimiterBySd(Map<int, double> sds, [List<String> candidates = DEFAULT_DELIMITERS]) {
    double minSd = double.MAX_FINITE;
    String delimiter = null;

    candidates.forEach((String candidate) {
      int candidateCode = code(candidate);
      if (sds.containsKey(candidateCode)) {
        double sd = sds[candidateCode];
        if (sd < minSd) {
          minSd = sd;
          delimiter = candidate;
        }
      }
    });

    return delimiter;
  }

  String guessQuote(List<String> rows, [List<String> candidates = DEFAULT_QUOTES]) {
    Map<String, int> counters = {};

    rows.forEach((String row) {
      Map<int, int> counts = rowCounts(row);
      candidates.forEach((String candidate) {
        int candidateCode = code(candidate);
        if (counts.containsKey(candidateCode) && counts[candidateCode] % 2 == 0) {
          if (counters.containsKey(candidate)) counters[candidate]++; else counters[candidate] = 1;
        }
      });
    });

    String quote = null;
    int maxCount = -1;
    counters.forEach((String key, int value) {
      if (value > maxCount) {
        maxCount = value;
        quote = key;
      }
    });

    return quote;
  }

  Map rowsStatistics(List<String> rows, [String quote]) {
    Map<int, int> rowsCounts = {};
    Map<int, double> standardDeviations = {};
    
    int quoteCode = code(quote);

    rows.forEach((String row) {
      Map<int, int> counts = rowCounts(row, quoteCode);
      merge(counts, rowsCounts);
      mergeSd(counts, standardDeviations);
    });

    Map<int, double> rowAvgs = avgs(rowsCounts, rows.length);
    finalizeSd(standardDeviations, rowAvgs, rows.length);

    return {
      "counts": rowsCounts,
      "avgs": rowAvgs,
      "sds": standardDeviations
    };
  }

  void merge(Map<int, int> source, Map<int, int> target) {
    source.forEach((int key, int value) {
      target[key] = (target.containsKey(key) ? target[key] : 0) + value;
    });
  }

  void mergeSd(Map<int, int> source, Map<int, double> target) {
    source.forEach((int key, int value) {
      target[key] = (target.containsKey(key) ? target[key] : 0) + pow(value.toDouble(), 2);
    });
  }

  void finalizeSd(Map<int, double> sd, Map<int, double> avgs, int cardinality) {
    double dcard = cardinality.toDouble();
    sd.forEach((int key, double value) {
      sd[key] = value - dcard * avgs[key] * avgs[key];
    });
  }

  Map<int, double> avgs(Map<int, int> counts, int cardinality) {
    Map<int, double> avgs = {};
    counts.forEach((int key, int value) {
      avgs[key] = counts[key] / cardinality;
    });
    return avgs;
  }

  Map<int, int> rowCounts(String row, [int quote]) {
    Map<int, int> counts = {};
    bool inQuote = false;
    row.codeUnits
    .forEach((int code) {
      if (code == quote) inQuote = !inQuote;
      else if (!inQuote) counts[code] = counts[code] == null ? 1 : counts[code] + 1;
    });
    return counts;
  }

  String guessNewLine(String content, [List<String> candidates = DEFAULT_NEW_LINES]) {

    int maxCount = -1;
    String newLine = null;

    candidates.forEach((String candidate) {
      int count = candidate.allMatches(content).length;
      if (count > maxCount) {
        maxCount = count;
        newLine = candidate;
      } else if (count == maxCount && candidate.contains(newLine)) {
        //replaces 'X' with 'XY' if both have same count
        newLine = candidate;
      }
    });

    return newLine;

  }

}


int code(String s) => s != null && s.isNotEmpty ? s.codeUnitAt(0) : null;

class CSVConfiguration {
  String newLine;
  String delimiter;
  String quote;

  String toString() => 'CSVConfiguration newLine: $newLine delimiter: $delimiter quote: $quote';
}


class CharStatistics {
  List<int> counts = [];

}
