import Array "mo:base/Array";
import Text "mo:base/Text";

module {
  public type FileReference = {
    path : Text;
    hash : Text;
  };

  public type Registry = {
    var files : [FileReference];
  };

  public func new() : Registry {
    {
      var files = [];
    }
  };

  public func add(registry : Registry, path : Text, hash : Text) {
    let newRef : FileReference = { path; hash };
    registry.files := Array.append(registry.files, [newRef]);
  };

  public func get(registry : Registry, path : Text) : FileReference {
    switch (Array.find<FileReference>(registry.files, func(ref : FileReference) : Bool { ref.path == path })) {
      case (?ref) ref;
      case null { path; hash = "" };
    };
  };

  public func list(registry : Registry) : [FileReference] {
    registry.files;
  };

  public func remove(registry : Registry, path : Text) {
    registry.files := Array.filter<FileReference>(
      registry.files,
      func(ref : FileReference) : Bool { ref.path != path }
    );
  };
}
