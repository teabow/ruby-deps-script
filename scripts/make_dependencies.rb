require 'json'

OUTPUT_PATH = ARGV[0] || "DEPENDENCIES.MD"
DELIMITER = ","

def extractFileFromPath(path)
    shortPath = path.scan /.*\/(.*)$/
    if shortPath.length > 0 && shortPath[0].length > 0
        return shortPath[0][0]
    else
        return path
    end
end

def parseNodeDependencies(file)
    package_json_content = File.read(file)
    package_json_map = JSON.parse(package_json_content)
    dependencies = package_json_map["dependencies"]
    return dependencies
end

def parsePodsDependencies(file)
    pod_dependencies_regex = /pod\s+['"]([\w\/-]+)['"]\s*(?:,)\s*['"](.*)['"]/
    podfile_content = File.read(file)
    dependencies = podfile_content.scan pod_dependencies_regex
    return dependencies
end

def parseGradleDependencies(file)
    gradle_dependencies_regex = /(?:implementation|api)\s+['"]([\w\-\.:]+):((?:[0-9\.]+)|(?:\$.+))['"]/
    gradle_file_content = File.read(file)
    dependencies = gradle_file_content.scan gradle_dependencies_regex
    return dependencies
end

def formatDependency(name, version)
    return "#{name} **(v#{version})**"
end

files = ARGV[1].split(DELIMITER)
outputContent = files.collect{ |filename|
    content = ["", []]
    shortenedFilename = extractFileFromPath(filename)
    if filename.match?(/package.json/)
        content = ["#{shortenedFilename} (web/node)", parseNodeDependencies(filename)]
    elsif filename.match?(/Podfile/)
        content = ["#{shortenedFilename} (iOS)", parsePodsDependencies(filename)]
    elsif filename.match?(/build.gradle/)
        content = ["#{shortenedFilename} (android)", parseGradleDependencies(filename)]
    end
    content
}

File.open(OUTPUT_PATH, "w") { |file|
    file.puts "# DEPENDENCIES"
    file.puts @string

    outputContent.each { |filename, dependencies|
        file.puts "# #{filename}"
        dependencies.each { |key, value|
            file.puts "- #{formatDependency(key, value)}"
        }
        file.puts @string
    }
}
