require 'json'

def sorted_generate(obj)
  case obj
    when Array
      arrayRet = []
      obj.each do |a|
        arrayRet.push(sorted_generate(a))
      end
      return "[" << arrayRet.join(',') << "]";
    when Hash
      ret = []
      obj.keys.sort.each do |k|
        ret.push(k.to_json << ":#{sorted_generate(obj[k])}")
      end
      return "{" << ret.join(",") << "}";
    when String
      return obj.to_json
    else
      return obj.to_json
  end
end # end def

def sorted_json(h)
  sorted_generate(h)
end

module Puppet::Parser::Functions
  newfunction(:dcos_sorted_json, :type => :rvalue, :doc => <<-EOS
This function takes data, outputs making sure the hash keys are sorted
*Examples:*
    sorted_json({'key'=>'value'})
Would return: {'key':'value'}
    EOS
  ) do |arguments|

    raise(Puppet::ParseError, "sorted_json(): Wrong number of arguments " +
      "given (#{arguments.size} for 1)") if arguments.size != 1

    json = arguments[0]
    return sorted_json(json)

  end
end
