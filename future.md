# Documentation

- Examples should include the full request / response, ideally also including the CURL debug statement. It needs tweaking the YARD template though and probably adding some new YARD functionality. It'd be @example which would contain @code and @return with the returned, reparsed JSON (rather than JSON itself, i. e. we should parse createdAt etc).

# CLI

- Do not require credentials when not actually required.
- Support --instance=mini etc.
- Add console.

# Development

- Workflow for gem release. Update RubyDoc.info. http://gnuu.org/2010/06/26/yard-object-oriented-diffing/
- Tests for bin/terminal.com.
