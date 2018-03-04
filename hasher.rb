#!/usr/bin/ruby

# hasher v1.0
# Copyright(C) 2018 Agaxia
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included
# UNALTERED in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


if ARGV.length < 3 || (format = ARGV[0]) =~ /\s|\t/
	print "Syntax: hasher <format> <outut file> <input files...>\n"
	exit
end

bin_paths = ENV['PATH'].split(':')
command = "#{format}sum"

if !bin_paths.index{|p| File.exists?("#{p}/#{command}")}.nil?
	get_hash = :first
else
	get_hash = :last
	command = format

	if bin_paths.index{|p| File.exists?("#{p}/#{command}")}.nil?
		if (openssl_formats = `openssl list-message-digest-commands` rescue false) &&
		   openssl_formats.include?(format)
			command = "openssl #{format}"
		else
			puts "Error: The format \"#{format}\" is not supported in this system."
			exit -1
		end
	end
end

$stdout.sync = true

progress = proc{
	bars = ["|", "/", "-", "\\"]
	loop{bars.each{|b| print "\b#{b}"; sleep 0.04}}
}

print "Creating file list...  "
t = Thread.new(&progress)


list = []

`find #{ARGV[2..(-1)].join(' ')} -type f`.each_line{|l|
	unless (i = l.index("$")).nil?
		l = "#{l[0,i]}\\#{l[i,l.length]}"
	end
	list << l.strip
}

list.sort!

t.kill
print "\rCreating file list... done!\n"

output_file_path = ARGV[1]

begin
	file = File.open(output_file_path, "w")
rescue SystemCallError => exception
	puts "Error: Cannot open file \"#{output_file_path}\" for writing."
	exit -exception.errno.abs
end

print "Calculating #{format.upcase} hashes: "
size = list.length

counter = 0
cs = 0
c = ""
b = ""
completed = 0

list.each do |path|
	c = "#{completed} % (#{counter} / #{size} files)"
	cs.times{print  "\b"}
	print c
	b = c.dup
	cs = c.length
	hash = `#{command} "#{path}"`.strip.split.__send__(get_hash)
	file.puts "#{hash}  #{path}"
	counter += 1
	completed = counter * 100 / list.length
end
print "\rCalculating SHA-1 checksums: 100 % completed! (#{counter} files processed)\n"
file.close
