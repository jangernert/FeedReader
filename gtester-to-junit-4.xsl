<?xml version="1.0"?>
<!-- created by R. Tyler Croy and improved by André Klitzing -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output indent="yes" method="xml" omit-xml-declaration="no" cdata-section-elements="system-out" />

  <xsl:template name="strreplace">
    <!-- Based on this code: http://geekswithblogs.net/Erik/archive/2008/04/01/120915.aspx -->
    <xsl:param name="string" />
    <xsl:param name="token" />
    <xsl:param name="newtoken" />
    <xsl:choose>
      <xsl:when test="contains($string, $token)">
        <xsl:value-of select="substring-before($string, $token)" />
        <xsl:value-of select="$newtoken" />
        <xsl:call-template name="strreplace">
          <xsl:with-param name="string" select="substring-after($string, $token)" />
          <xsl:with-param name="token" select="$token" />
          <xsl:with-param name="newtoken" select="$newtoken" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$string" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="remove-lf-left">
    <!-- Based on this code: http://dpawson.co.uk/xsl/sect2/N8321.html#d11325e833 -->
    <xsl:param name="astr" />
    <xsl:choose>
      <xsl:when test="starts-with($astr,'&#xA;') or starts-with($astr,'&#xD;')">
        <xsl:call-template name="remove-lf-left">
          <xsl:with-param name="astr" select="substring($astr, 2)" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$astr" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="sysout">
    random-seed: <xsl:value-of select="random-seed" />
    <xsl:for-each select="testcase">
      <xsl:variable name="classname">
        <xsl:call-template name="strreplace">
          <xsl:with-param name="string" select="substring-after(@path, '/')" />
          <xsl:with-param name="token" select="'/'" />
          <xsl:with-param name="newtoken" select="'.'" />
        </xsl:call-template>
      </xsl:variable>
      Start test '<xsl:value-of select="$classname" />':
      ---------------------------------------------------------------------
      <xsl:for-each select="message">
        <xsl:call-template name="remove-lf-left">
          <xsl:with-param name="astr" select="." />
        </xsl:call-template>
      </xsl:for-each>
      ---------------------------------------------------------------------
      End test '<xsl:value-of select="$classname" />'
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="/">
    <testsuites>
      <xsl:for-each select="gtester">

        <xsl:for-each select="testbinary">
          <testsuite>
            <xsl:attribute name="name">
              <xsl:value-of select="@path" />
            </xsl:attribute>
            <xsl:attribute name="tests">
              <xsl:value-of select="count(testcase)" />
            </xsl:attribute>
            <xsl:attribute name="time">
              <xsl:value-of select="sum(testcase/duration)" />
            </xsl:attribute>
            <xsl:attribute name="failures">
              <xsl:value-of select="count(testcase/status[@result='failed'])" />
            </xsl:attribute>

            <xsl:for-each select="testcase">
              <testcase>
                <xsl:variable name="classname">
                  <xsl:call-template name="strreplace">
                    <xsl:with-param name="string" select="substring-after(@path, '/')" />
                    <xsl:with-param name="token" select="'/'" />
                    <xsl:with-param name="newtoken" select="'.'" />
                  </xsl:call-template>
                </xsl:variable>
                <xsl:attribute name="classname">
                  <xsl:value-of select="$classname" />
                </xsl:attribute>
                <xsl:attribute name="name">
                  <xsl:value-of select="$classname" />
                </xsl:attribute>
                <xsl:attribute name="time">
                  <xsl:value-of select="duration" />
                </xsl:attribute>
                <xsl:if test="status[@result = 'failed']">
                  <failure>
                    <xsl:value-of select="error" />
                  </failure>
                </xsl:if>
              </testcase>
            </xsl:for-each>

            <system-out>
              <xsl:call-template name="sysout" />
            </system-out>
            <system-err></system-err>
          </testsuite>
        </xsl:for-each>

      </xsl:for-each>
    </testsuites>
  </xsl:template>

</xsl:stylesheet>
