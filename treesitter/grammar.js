module.exports = grammar({
  name: 'rafta_nvim',

  extras: $ => [/[ \t]/],

  conflicts: $ => [
    [$._lhs],
  ],

  rules: {
    // Root rule: a taskbuffer file containing multiple task lines
    source_file: $ => repeat(choice(
      seq($.task, '\n'),
      $.task
    )),

    // Each line is exactly one task - try structured parsing, then fallback to title
    task: $ => choice(
      // Try: _lhs + title (structured task with title) - high precedence
      prec(10, seq($._lhs, $.title)),
      // Try: _lhs only (structured task without title) - high precedence
      prec(9, $._lhs),
      // Fallback: entire line is title - low precedence
      prec(1, $.title)
    ),

    // Left-hand side: at least one field, in strict order (short_id, state, priority)
    _lhs: $ => choice(
      // With short_id - can be followed by optional state and priority
      seq($.short_id, optional($.state), optional($.priority)),
      // Without short_id, with state - can be followed by optional priority
      seq($.state, optional($.priority)),
      // Only priority
      $.priority
    ),

    // Components with high token precedence to prefer structured parsing
    short_id: $ => token(prec(5, seq('/', /[0-9A-Fa-f]+/))),
    // state: $ => token(prec(5, /[x.~\-?]/)),
    state: $ => token(prec(5, choice(
      '?',  // UNSPECIFIED
      '.',  // PENDING
      '~',  // ONGOING
      'x',  // DONE
      '-',  // BLOCKED
    ))),
    priority: $ => token(prec(5, seq('(', /[0-9]+/, ')'))),

    // Title: consume rest of line (can be empty) - very low precedence
    title: $ => token(prec(-5, /[^\r\n]*/)),
  }
});
