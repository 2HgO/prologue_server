type
  ContextLogger* = concept c
    c.info(string, varargs[string, `$`])
    c.debug(string, varargs[string, `$`])
    c.error(string, varargs[string, `$`])
