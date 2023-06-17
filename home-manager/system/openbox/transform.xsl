<?xml version='1.0' encoding='UTF-8'?>
<xsl:stylesheet
  xmlns="http://openbox.org/3.4/rc"
  xmlns:xsl='http://www.w3.org/1999/XSL/Transform' version='2.0'
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:functx="http://www.functx.com"
  xmlns:sn="https://shados.net"
  >
  <xsl:template match='/'>
    <openbox_config>
      <xsl:apply-templates select="expr/attrs"/>
    </openbox_config>
  </xsl:template>

  <!-- Top-level nodes -->
  <xsl:template match="/expr/attrs/attr[@name=(
      'resistance',
      'focus',
      'placement',
      'desktops',
      'resize',
      'applications',
      'keyboard',
      'mouse',
      'margins',
      'menu',
      'theme',
      'dock'
    )]">
    <xsl:element name="{@name}">
      <xsl:apply-templates select="attrs/attr | list/attrs" />
    </xsl:element>
  </xsl:template>

  <!-- Handle flat options within top-level nodes -->
  <xsl:template match="/expr/attrs/attr/attrs[attr[bool | string | int]]">
    <xsl:apply-templates select="attr" />
  </xsl:template>

  <!-- Generic handling of flat options -->
  <!-- Bools -->
  <xsl:template match="attr[bool]">
    <xsl:element name="{@name}">
      <xsl:value-of select="sn:ob-bool(bool/@value)" />
    </xsl:element>
  </xsl:template>
  <!-- Strings and ints -->
  <xsl:template match="attr[string | int]">
    <xsl:element name="{@name}">
      <xsl:value-of select="*[1]/@value" />
    </xsl:element>
  </xsl:template>

  <!-- Handling of structured options within top-level nodes -->
  <!-- Handle applications -->
  <xsl:template match="/expr/attrs/attr/list/attrs">
    <application>
      <xsl:for-each select="attr[@name=('class', 'name', 'groupname', 'groupclass', 'role', 'title', 'type')]">
        <xsl:if test="string/@value != ''">
          <xsl:attribute name="{@name}">
            <xsl:value-of select="string/@value" />
          </xsl:attribute>
        </xsl:if>
      </xsl:for-each>
      <xsl:for-each select="attr[@name!='_module']">
        <xsl:choose>
          <xsl:when test="@name=('class', 'name', 'groupname', 'groupclass', 'role', 'title', 'type')">
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="."/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </application>
  </xsl:template>

  <!-- Handle Menu files -->
  <xsl:template match="/expr/attrs/attr/attrs/attr[@name = 'file']">
    <xsl:for-each select="list/string">
      <file>
        <xsl:value-of select="@value" />
      </file>
    </xsl:for-each>
  </xsl:template>

  <!-- Map keybinds -->
  <xsl:template match="/expr/attrs/attr/attrs/attr[@name = 'keybind']">
    <xsl:for-each select="attrs/attr">
      <xsl:call-template name="keybind" />
    </xsl:for-each>
  </xsl:template>
  <xsl:template name="keybind">
    <keybind>
      <xsl:attribute name="key">
        <xsl:value-of select="@name" />
      </xsl:attribute>
      <xsl:for-each select="list/attrs">
        <xsl:call-template name="action" />
      </xsl:for-each>
    </keybind>
  </xsl:template>
  <xsl:template name="action">
    <action>
      <xsl:attribute name="name">
        <xsl:value-of select="attr[@name = 'action']/string/@value" />
      </xsl:attribute>
      <!-- Handle flat options within keybinds -->
      <xsl:apply-templates select="attr[@name != 'action'][(bool | string | int)]" />
      <!-- Handle nested options within keybinds -->
      <xsl:apply-templates select="attr[@name != 'action'][attrs]" />
    </action>
  </xsl:template>

  <!-- Mouse nodes -->
  <xsl:template match="/expr/attrs/attr/attrs/attr[@name = 'mousebind']">
    <xsl:for-each select="attrs/attr">
      <context>
        <xsl:attribute name="name">
          <xsl:value-of select="@name" />
        </xsl:attribute>
        <xsl:for-each select="list/attrs">
          <xsl:call-template name="mousebind" />
        </xsl:for-each>
      </context>
      <!-- <xsl:call-template name="mousebind-context" /> -->
    </xsl:for-each>
  </xsl:template>
  <xsl:template name="mousebind">
    <mousebind>
      <xsl:attribute name="button">
        <xsl:value-of select="attr[@name='button']/string/@value" />
      </xsl:attribute>
      <xsl:attribute name="action">
        <xsl:value-of select="attr[@name='action']/string/@value" />
      </xsl:attribute>
      <xsl:for-each select="attr[@name='actions']/list/attrs">
        <xsl:call-template name="action" />
      </xsl:for-each>
    </mousebind>
  </xsl:template>

  <!-- Theme nodes -->
  <xsl:template match="/expr/attrs/attr/attrs/attr[@name = 'fonts']">
    <xsl:for-each select="attrs/attr">
      <font>
        <xsl:attribute name="name">
          <xsl:value-of select="@name" />
        </xsl:attribute>
        <xsl:apply-templates select="attrs/attr[@name != '_module']" />
      </font>
      <!-- <xsl:element name="{@name}"> -->
      <!-- </xsl:element> -->
      <!-- <context> -->
      <!--   <xsl:attribute name="name"> -->
      <!--     <xsl:value-of select="@name" /> -->
      <!--   </xsl:attribute> -->
      <!--   <xsl:for-each select="list/attrs"> -->
      <!--     <xsl:call-template name="mousebind" /> -->
      <!--   </xsl:for-each> -->
      <!-- </context> -->
      <!-- <xsl:call-template name="mousebind-context" /> -->
    </xsl:for-each>
  </xsl:template>

  <!-- Helper functions -->
  <xsl:function name="sn:ob-bool" as="xs:string">
    <xsl:param name="arg" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="$arg = 'true'">
        <xsl:sequence select="'yes'" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="'no'" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  <xsl:function name="sn:camel-case-to-snake-case" as="xs:string">
    <xsl:param name="arg" as="xs:string?"/>
    <xsl:sequence select="lower-case(functx:camel-case-to-words($arg,'_'))" />
  </xsl:function>

  <xsl:function name="functx:camel-case-to-words" as="xs:string">
    <xsl:param name="arg" as="xs:string?"/>
    <xsl:param name="delim" as="xs:string"/>

    <xsl:sequence select="
      concat(
        substring($arg,1,1),
        replace(
          substring($arg,2),
          '(\p{Lu})',
          concat($delim, '$1')
        )
      )
    "/>
  </xsl:function>
</xsl:stylesheet>
