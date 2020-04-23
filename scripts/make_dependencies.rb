require 'json'

OUTPUT_PATH = ARGV[0] || "DEPENDENCIES.MD"
DELIMITER = ","

def extract_file_from_path(path)
    short_path = path.scan /.*\/(.*)$/
    if short_path.length > 0 && short_path[0].length > 0
        return short_path[0][0]
    else
        return path
    end
end

def parse_node_dependencies(file)
    package_json_content = File.read(file)
    package_json_map = JSON.parse(package_json_content)
    dependencies = package_json_map["dependencies"]
    return dependencies
end

def parse_pods_dependencies(file)
    pod_dependencies_regex = /pod\s+['"]([\w\/-]+)['"]\s*(?:,)\s*['"](.*)['"]/
    podfile_content = File.read(file)
    dependencies = podfile_content.scan pod_dependencies_regex
    return dependencies
end

def parse_gradle_dependencies(file)
    gradle_dependencies_regex =
        /(?:([a-zA-Z_-]+[vV]ersion)\s+=\s+["'](.*)["'])|(?:implementation|api)\s+['"]([\w\-\.:]+):((?:[0-9\.]+)|(?:\$.+))['"]/

    gradle_file_content = File.read(file)
    gradle_dependencies = gradle_file_content.scan gradle_dependencies_regex

    versions_hash = gradle_dependencies.reduce({}) { |acc, (version_key, version_value)|
        unless version_key.nil? and version_value.nil?
            acc.merge({ "$#{version_key}" => version_value })
        else
            acc
        end
    }

    dependencies = gradle_dependencies.reduce([]) { |acc, (version_name, version_number, dependency_name, dependency_version)|
        unless dependency_name.nil? and dependency_version.nil?
            [*acc, [dependency_name, dependency_version]]
        else
            acc
        end
    }

    return [versions_hash, dependencies]
end

def format_dependency(name, version, versions_ref)
    version_key = versions_ref["#{version}"] || version
    return "#{name} **(v#{version_key})**"
end

files = ARGV[1].split(DELIMITER)
versions_hash_ref = {}
output_content = files.collect{ |filename|
    content = ["", []]
    shortened_filename = extract_file_from_path(filename)
    if filename.match?(/package.json/)
        content = ["#{shortened_filename} (web/node)", parse_node_dependencies(filename)]
    elsif filename.match?(/Podfile/)
        content = ["#{shortened_filename} (iOS)", parse_pods_dependencies(filename)]
    elsif filename.match?(/app\/build.gradle/)
        # process root gradle file
        root_gradle_path = filename.gsub("/app", "")
        (root_versions_hash_ref, _) = parse_gradle_dependencies(root_gradle_path)
        # process app gradle file
        (app_versions_hash_ref, gradle_dependencies) = parse_gradle_dependencies(filename)
        versions_hash_ref = root_versions_hash_ref.merge(app_versions_hash_ref)
        content = ["#{shortened_filename} (android)", gradle_dependencies]
    elsif filename.match?(/build.gradle/)
        (versions_hash_ref, gradle_dependencies) = parse_gradle_dependencies(filename)
        content = ["#{shortened_filename} (android)", gradle_dependencies]
    end
    content
}

File.open(OUTPUT_PATH, "w") { |file|
    file.puts "# DEPENDENCIES"
    file.puts @string

    output_content.each { |filename, dependencies|
        file.puts "# #{filename}"
        dependencies.each { |key, value|
            file.puts "- #{format_dependency(key, value, versions_hash_ref)}"
        }
        file.puts @string
    }
}
