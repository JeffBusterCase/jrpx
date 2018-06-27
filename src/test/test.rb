def parse_require_calls str
    str.scan(/\s*require\s*\(?['|"](.+?)['|"]\)?/).select {|name|
        _name = name[0].strip()
        _name[0..1] == './' && _name[-4..-1] != '.jar'
    }.map {|name|
        _name = name[0].strip()
        _name[-3..-1] == '.rb' ? _name : _name+'.rb'
    }
end

def clear_require_calls str, requires
    requires.each do |r|
        _r = r[0..-4]
        str = str.gsub(/\s*require\s*\(?['|"]\s*#{_r}(\.rb)?\s*['|"]\)?/, '')
    end
    str
end

a = [1,2,3]

a.each {|i|
    a << 2 if i%2==0
    break if a.size ==10
}

p a