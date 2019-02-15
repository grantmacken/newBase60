define expathPkgXML
<package xmlns="http://expath.org/ns/pkg"
  name="$(nsname)"
  abbrev="$(NAME)"
  spec="1.0"
  version="$(patsubst v%,%,$(VERSION))">
  <title>$(title)</title>
  <xquery>
   <namespace>$(nsname)</namespace>
   <file>$(NAME).xqm</file>
  </xquery>
</package>
endef
