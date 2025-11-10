import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Debug "mo:base/Debug";

module {
  public type UserRole = {
    #admin;
    #user;
    #guest;
  };

  public type Permission = {
    #admin;
    #user;
  };

  public type State = {
    var owner : ?Principal;
    var admins : [Principal];
    var users : [(Principal, UserRole)];
  };

  public func initState() : State {
    {
      var owner = null;
      var admins = [];
      var users = [];
    }
  };

  public func initialize(state : State, caller : Principal) {
    switch (state.owner) {
      case null {
        state.owner := ?caller;
        state.admins := [caller];
      };
      case (?_) {
        Debug.trap("Already initialized");
      };
    };
  };

  public func getUserRole(state : State, user : Principal) : UserRole {
    if (Array.find<Principal>(state.admins, func(p : Principal) : Bool { p == user }) != null) {
      return #admin;
    };
    
    switch (Array.find<(Principal, UserRole)>(state.users, func((p, _) : (Principal, UserRole)) : Bool { p == user })) {
      case (?(_, role)) role;
      case null #guest;
    };
  };

  public func assignRole(state : State, caller : Principal, user : Principal, role : UserRole) {
    if (not isAdmin(state, caller)) {
      Debug.trap("Unauthorized: Only admins can assign roles");
    };

    state.users := Array.filter<(Principal, UserRole)>(
      state.users,
      func((p, _) : (Principal, UserRole)) : Bool { p != user }
    );
    state.users := Array.append(state.users, [(user, role)]);

    if (role == #admin) {
      if (Array.find<Principal>(state.admins, func(p : Principal) : Bool { p == user }) == null) {
        state.admins := Array.append(state.admins, [user]);
      };
    };
  };

  public func isAdmin(state : State, user : Principal) : Bool {
    Array.find<Principal>(state.admins, func(p : Principal) : Bool { p == user }) != null
  };

  public func hasPermission(state : State, user : Principal, permission : Permission) : Bool {
    switch (permission) {
      case (#admin) isAdmin(state, user);
      case (#user) {
        isAdmin(state, user) or getUserRole(state, user) != #guest
      };
    };
  };
}
