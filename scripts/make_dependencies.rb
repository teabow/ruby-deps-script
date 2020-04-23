require 'json'

OUTPUT_PATH = ARGV[0] || "DEPENDENCIES.MD"
DELIMITER = ","

def parseNodeDependencies(file)
    package_json_content = File.read(file)
    package_json_map = JSON.parse(package_json_content)
    dependencies = package_json_map["dependencies"]
    return dependencies
    #return { "file" => file, "dependencies" => dependencies }
end

def parsePodsDependencies(file)
    pod_dependencies_regex = /pod\s+['"]([\w\/-]+)['"]\s*(?:,)\s*['"](.*)['"]/
    podfile_content = File.read(file)
    dependencies = podfile_content.scan pod_dependencies_regex
    return dependencies
    #return { "file" => file, "dependencies" => dependencies }
end

def parseGradleDependencies(file)
    gradle_dependencies_regex = /(?:implementation|api)\s+['"]([\w\-\.:]+):((?:[0-9\.]+)|(?:\$.+))['"]/
    gradle_file_content = File.read(file)
    dependencies = gradle_file_content.scan gradle_dependencies_regex
    return dependencies
    #return { "file" => file, "dependencies" => dependencies }
end

files = ARGV[1].split(DELIMITER)
outputContent = files.collect{ |filename|
    content = ""
    if filename.match?(/package.json/)
        content = parseNodeDependencies(filename)
    elsif filename.match?(/Podfile/)
        content = parsePodsDependencies(filename)
    elsif filename.match?(/build.gradle/)
        content = parseGradleDependencies(filename)
    end
    content
}

File.open(OUTPUT_PATH, "w") { |file|
    file.puts "# DEPENDENCIES"
    file.puts @string

    outputContent.each { |dependencies|
        # file.puts "# #{filename}"
        dependencies.each { |key, value|
            file.puts "- #{key} : #{value}"
        }
        file.puts @string
    }
}
