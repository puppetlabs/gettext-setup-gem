# StringWrapper
#
# A script for use with whitequark's Ruby parsing library, which wraps strings with `_()`, the method used by the gettext gem to identify strings which need to be extracted into a POT file.
#
# Run with `ruby-rewrite -m --load string_wrapper.rb <file_or_dir_to_mark>`. This will modify the file(s) in place.
#
# Note: the changes made by this script still need a thorough manual review, to ensure that _only_ strings that need to be externalized are marked. More sophisticated matching criteria will be added as they are discovered through use of the script on complex files.
#
# For more info on the parser/rewriter, see <https://github.com/whitequark/parser>.
#
# This script was originally written by Maggie Dryer and changes made by Eric Putnam.

class StringWrapper < Parser::Rewriter
  def on_dstr(node)
    if node.loc.respond_to?(:heredoc_body)
      insert_before(node.loc.expression, '_(')
      insert_after(node.loc.expression, ')')
    elsif node.loc.respond_to?(:begin)
      insert_before(node.loc.begin, '_(')
      insert_after(node.loc.end, ')')
    end
  end

  def on_str(node)
    if node.loc.respond_to?(:heredoc_body)
      insert_before(node.loc.expression, '_(')
      insert_after(node.loc.expression, ')')
    elsif node.loc.respond_to?(:begin)
      # avoid constants, like __FILE__, which do not have begin/end nodes and should not be marked
      str = node.children[0]
      return if str == ''         # ignore empty strings
      return if str !~ /[A-Za-z]/ # ignore non-text strings
      return if str =~ /^\.*\//   # ignore many file paths
      # ignore strings with no whitespace - are typically keywords or interpolation statements and cover the above commented-out statements
      return if str =~ /^\S*$/
      insert_before(node.loc.begin, '_(')
      insert_after(node.loc.end, ')')
    end
  end

  def on_send(node)
    method_name = node.loc.selector.source
    return unless /call_function|function_deprecation|new(param|function|property)|raise|desc|\+|.*[Ee]rror|warning|warn|fail/=~method_name
    if method_name == 'raise'
      _receiver_node, _method_name, *arg_nodes = *node
      if !arg_nodes.empty? && arg_nodes[0].type == :const
        # skip errors that are only logged in debug mode
        return if arg_nodes[0].loc.name.source == 'DevError'
      end
    end
    super
  end

  def on_regexp(_node)
    nil
  end

  def on_array(_node)
    nil
  end

  def on_xstr(_node)
    nil
  end
end
