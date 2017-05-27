import io.github.weakish.sysexits {
    NotImplementedYetException,
    InternalSoftwareError
}
import ceylon.process {
    Process,
    createProcess
}
import ceylon.file {
    Reader
}
"Try to get hostname via environment virable.
 If failed, get hostname via running `hostname`."
String get_hostname() {
    String? enviroment_variable;
    if (operatingSystem.name == "windows") {
        enviroment_variable = process.environmentVariableValue("COMPUTERNAME");
    } else if (["linux", "mac", "unix", "other"].contains(operatingSystem.name)) {
        // Bash or derivatives sets the HOSTNAME variable.
        enviroment_variable = process.environmentVariableValue("HOSTNAME");
    } else {
        throw NotImplementedYetException(
            "Support for os ``operatingSystem.name`` is not implemented.");
    }

    switch (enviroment_variable)
    case (is String) {
        return enviroment_variable;
    }
    case (is Null) {
        String host_name;
        Process process = createProcess("hostname");
        if (is Reader reader = process.output) {
            if (is String line = reader.readLine()) {
                host_name = line;
            } else {
                throw InternalSoftwareError("`hostname` has an empty output!");
            }
        } else {
            throw InternalSoftwareError("`hostname` has a wrong output stream!");
        }
        switch (exit_code = process.waitForExit())
        case (0) {
            return host_name;
        } else {
            throw InternalSoftwareError("`hostname` failed with exit code ``exit_code``");
        }
    }
}