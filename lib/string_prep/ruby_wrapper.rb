require 'pry'
#require 'pry-nav'
require 'parser'

class StringWrapper < Parser::Rewriter
  def on_dstr(node)
    if node.loc.respond_to?(:heredoc_body)
      insert_before(node.loc.expression, "_(")
      insert_after(node.loc.expression, ")")
    elsif node.loc.respond_to?(:begin)
      insert_before(node.loc.begin, "_(")
      insert_after(node.loc.end, ")")
    end
  end

  def on_str(node)
    if node.loc.respond_to?(:heredoc_body)
      insert_before(node.loc.expression, "_(")
      insert_after(node.loc.expression, ")")
    elsif node.loc.respond_to?(:begin)
      # avoid constants, like __FILE__, which do not have begin/end nodes,
      # and should not be marked
      str = node.children[0]
      return if str == ""         # ignore empty strings
      return if str !~ /[A-Za-z]/ # ignore non-text strings
      return if str =~ /^\.*\//   # ignore many file paths
      #return if str =~ /^true|^false/ #ignore true/false
      #return if str =~ /^[Aa]bsent|^[Pp]resent/ #ignore ensure values
      #return if str =~ /^w$|^r$|^w\+$|^r\+$/ #ignore file modes
      #ignore strings with no whitespace - are typically keywords or interpolation statements and cover the above commented-out statements
      return if str =~ /^\S*$/
      insert_before(node.loc.begin, "_(")
      insert_after(node.loc.end, ")")
    end
  end

  def on_send(node)
    method_name = node.loc.selector.source
    return if !/call_function|function_deprecation|new(param|function|property)|puts|raise|desc|\+|.*[Ee]rror|[Dd]ebug|warning|warn|fail|notice/.match(method_name)
    if method_name == "raise"
      receiver_node, method_name, *arg_nodes = *node
      if !arg_nodes.empty? && arg_nodes[0].type == :const
        # skip errors that are only logged in debug mode
        return if arg_nodes[0].loc.name.source == "DevError"
      end
    end
    super
  end

  def on_regexp(node)
    return
  end

  def on_array(node)
    return
  end

  def on_xstr(node)
    return
  end
end

