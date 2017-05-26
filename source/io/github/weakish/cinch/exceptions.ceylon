class FileSizeMismatchException(shared String file_path) extends Exception(file_path) {}

class XattrNotEnabledException(shared String error_message) extends Exception(error_message) {}
