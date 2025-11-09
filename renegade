import OrderedMap "mo:base/OrderedMap";
import BlobStorage "blob-storage/Mixin";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Registry "blob-storage/registry";
import AccessControl "authorization/access-control";
import OutCall "http-outcalls/outcall";
import Blob "mo:base/Blob";
import Nat64 "mo:base/Nat64";
import Int "mo:base/Int";
import Debug "mo:base/Debug";

actor BowlingScoreTracker {
  transient let textMap = OrderedMap.Make<Text>(Text.compare);
  transient let principalMap = OrderedMap.Make<Principal>(Principal.compare);
  transient let natMap = OrderedMap.Make<Nat>(Nat.compare);

  type Player = {
    name : Text;
    scores : [Nat];
    averageScore : Nat;
    totalSpares : Nat;
    totalStrikes : Nat;
    totalPoints : Nat;
    highestScore : Nat;
    gamesPlayed : Nat;
  };

  type Frame = {
    roll1 : Nat;
    roll2 : Nat;
    roll3 : ?Nat;
    score : Nat;
  };

  type Game = {
    id : Nat;
    players : [Player];
    frames : [[Frame]];
    timestamp : Int;
    totalScores : [Nat];
    owner : ?Principal;
  };

  type ChatMessage = {
    sender : Text;
    message : Text;
    timestamp : Int;
    gameId : Nat;
  };

  type UserProfile = {
    principal : Principal;
    displayName : Text;
    games : [Nat];
    achievements : [Text];
    averageScore : Nat;
    totalSpares : Nat;
    totalStrikes : Nat;
    totalPoints : Nat;
    highestScore : Nat;
    gamesPlayed : Nat;
    profilePicture : ?Text;
  };

  type Team = {
    id : Nat;
    name : Text;
    description : Text;
    creator : Principal;
    members : [Principal];
    averageScore : Nat;
    totalGames : Nat;
    bestScore : Nat;
    createdAt : Int;
  };

  type JoinRequest = {
    teamId : Nat;
    requester : Principal;
    timestamp : Int;
  };

  type Invitation = {
    teamId : Nat;
    invitee : Principal;
    inviter : Principal;
    timestamp : Int;
  };

  type TokenPool = {
    name : Text;
    total : Nat;
    remaining : Nat;
  };

  type TokenTransaction = {
    id : Nat;
    from : ?Principal;
    to : ?Principal;
    amount : Nat;
    timestamp : Int;
    transactionType : Text;
    pool : ?Text;
    status : Text;
    reference : ?Text;
  };

  type PaymentTransaction = {
    id : Nat;
    user : Principal;
    icpAmount : Nat64;
    stkAmount : Nat;
    exchangeRate : Nat;
    timestamp : Int;
    status : Text;
    reference : ?Text;
  };

  type PriceFeed = {
    source : Text;
    icpUsd : Nat;
    lastUpdated : Int;
    status : Text;
  };

  type Wallet = {
    stkBalance : Nat;
    icpTransactions : [TokenTransaction];
    stkTransactions : [TokenTransaction];
    icpAccountId : Text;
    stkPrincipalId : Text;
  };

  type AccountBalanceArgs = {
    account : Blob;
  };

  type Tokens = {
    e8s : Nat64;
  };

  type Ledger = actor {
    account_balance : shared AccountBalanceArgs -> async Tokens;
    transfer : shared {
      memo : Nat64;
      amount : { e8s : Nat64 };
      fee : { e8s : Nat64 };
      from_subaccount : ?Blob;
      to : Blob;
      created_at_time : ?{ timestamp_nanos : Nat64 };
    } -> async { height : Nat64 };
  };

  type Result<Ok, Err> = {
    #ok : Ok;
    #err : Err;
  };

  var nextGameId = 0;
  var nextTeamId = 0;
  var nextTransactionId = 0;
  var nextPaymentId = 0;
  var games : OrderedMap.Map<Text, Game> = textMap.empty<Game>();
  var playerStats : OrderedMap.Map<Text, Player> = textMap.empty<Player>();
  var chatMessages : [ChatMessage] = [];
  var userProfiles : OrderedMap.Map<Principal, UserProfile> = principalMap.empty<UserProfile>();
  var teams : OrderedMap.Map<Nat, Team> = natMap.empty<Team>();
  var joinRequests : [JoinRequest] = [];
  var invitations : [Invitation] = [];
  var tokenPools : OrderedMap.Map<Text, TokenPool> = textMap.empty<TokenPool>();
  var tokenTransactions : OrderedMap.Map<Nat, TokenTransaction> = natMap.empty<TokenTransaction>();
  var paymentTransactions : OrderedMap.Map<Nat, PaymentTransaction> = natMap.empty<PaymentTransaction>();
  var priceFeeds : OrderedMap.Map<Text, PriceFeed> = textMap.empty<PriceFeed>();
  var userBalances : OrderedMap.Map<Principal, Nat> = principalMap.empty<Nat>();
  var userWallets : OrderedMap.Map<Principal, Wallet> = principalMap.empty<Wallet>();
  var totalSupply = 1000000;
  var isInitialized = false;
  let registry = Registry.new();
  let accessControlState = AccessControl.initState();

  // Helper function for safe subtraction
  func safeSub(a : Nat, b : Nat) : Nat {
    if (a < b) 0 else a - b;
  };

  // Initialize token pools on first run
  func initializeTokenPools() {
    if (not isInitialized) {
      let treasuryReserves : TokenPool = {
        name = "Treasury Reserves";
        total = 400000;
        remaining = 400000;
      };

      let mintingPlatform : TokenPool = {
        name = "Minting Platform";
        total = 200000;
        remaining = 200000;
      };

      let inGameRewards : TokenPool = {
        name = "In-Game Rewards";
        total = 150000;
        remaining = 150000;
      };

      let adminTeamWallet : TokenPool = {
        name = "Admin Team Wallet";
        total = 150000;
        remaining = 150000;
      };

      let nftStakingRewards : TokenPool = {
        name = "NFT Staking Rewards";
        total = 100000;
        remaining = 100000;
      };

      tokenPools := textMap.put(tokenPools, "Treasury Reserves", treasuryReserves);
      tokenPools := textMap.put(tokenPools, "Minting Platform", mintingPlatform);
      tokenPools := textMap.put(tokenPools, "In-Game Rewards", inGameRewards);
      tokenPools := textMap.put(tokenPools, "Admin Team Wallet", adminTeamWallet);
      tokenPools := textMap.put(tokenPools, "NFT Staking Rewards", nftStakingRewards);

      isInitialized := true;
    };
  };

  // Call initialization on canister upgrade/install
  system func postupgrade() {
    initializeTokenPools();
  };

  public shared ({ caller }) func initializeAccessControl() : async () {
    AccessControl.initialize(accessControlState, caller);
    initializeTokenPools(); // Ensure pools are initialized
  };

  public query ({ caller }) func getCallerUserRole() : async AccessControl.UserRole {
    AccessControl.getUserRole(accessControlState, caller);
  };

  public shared ({ caller }) func assignCallerUserRole(user : Principal, role : AccessControl.UserRole) : async () {
    AccessControl.assignRole(accessControlState, caller, user, role);
  };

  public query ({ caller }) func isCallerAdmin() : async Bool {
    AccessControl.isAdmin(accessControlState, caller);
  };

  public query ({ caller }) func getCallerUserProfile() : async ?UserProfile {
    principalMap.get(userProfiles, caller);
  };

  public query func getUserProfile(user : Principal) : async ?UserProfile {
    principalMap.get(userProfiles, user);
  };

  public shared ({ caller }) func saveCallerUserProfile(profile : UserProfile) : async () {
    let updatedProfile : UserProfile = {
      profile with principal = caller
    };
    userProfiles := principalMap.put(userProfiles, caller, updatedProfile);
  };

  public func saveGame(players : [Player], frames : [[Frame]], totalScores : [Nat], owner : ?Principal) : async Nat {
    let gameId = nextGameId;
    nextGameId += 1;

    let game : Game = {
      id = gameId;
      players;
      frames;
      timestamp = Time.now();
      totalScores;
      owner;
    };

    games := textMap.put(games, Nat.toText(gameId), game);

    for (player in players.vals()) {
      let existingPlayer = textMap.get(playerStats, player.name);
      let updatedScores = switch (existingPlayer) {
        case (?p) Array.append(p.scores, player.scores);
        case null player.scores;
      };
      let total = Array.foldLeft(updatedScores, 0, func(acc : Nat, score : Nat) : Nat { acc + score });
      let average = if (updatedScores.size() > 0) total / updatedScores.size() else 0;

      let updatedPlayer : Player = {
        name = player.name;
        scores = updatedScores;
        averageScore = average;
        totalSpares = switch (existingPlayer) {
          case (?p) p.totalSpares;
          case null 0;
        };
        totalStrikes = switch (existingPlayer) {
          case (?p) p.totalStrikes;
          case null 0;
        };
        totalPoints = switch (existingPlayer) {
          case (?p) p.totalPoints;
          case null 0;
        };
        highestScore = switch (existingPlayer) {
          case (?p) p.highestScore;
          case null 0;
        };
        gamesPlayed = switch (existingPlayer) {
          case (?p) p.gamesPlayed;
          case null 0;
        };
      };
      playerStats := textMap.put(playerStats, player.name, updatedPlayer);
    };

    switch (owner) {
      case (?principal) {
        let existingProfile = principalMap.get(userProfiles, principal);
        let updatedGames = switch (existingProfile) {
          case (?profile) Array.append(profile.games, [gameId]);
          case null [gameId];
        };
        let totalScoreSum = Array.foldLeft(totalScores, 0, func(acc : Nat, score : Nat) : Nat { acc + score });
        let averageScore = if (totalScores.size() > 0) {
          totalScoreSum / totalScores.size();
        } else { 0 };

        let updatedProfile : UserProfile = {
          principal;
          displayName = switch (existingProfile) {
            case (?profile) profile.displayName;
            case null Principal.toText(principal);
          };
          games = updatedGames;
          achievements = switch (existingProfile) {
            case (?profile) profile.achievements;
            case null [];
          };
          averageScore;
          totalSpares = switch (existingProfile) {
            case (?profile) profile.totalSpares;
            case null 0;
          };
          totalStrikes = switch (existingProfile) {
            case (?profile) profile.totalStrikes;
            case null 0;
          };
          totalPoints = switch (existingProfile) {
            case (?profile) profile.totalPoints;
            case null 0;
          };
          highestScore = switch (existingProfile) {
            case (?profile) profile.highestScore;
            case null 0;
          };
          gamesPlayed = switch (existingProfile) {
            case (?profile) profile.gamesPlayed;
            case null 0;
          };
          profilePicture = switch (existingProfile) {
            case (?profile) profile.profilePicture;
            case null null;
          };
        };
        userProfiles := principalMap.put(userProfiles, principal, updatedProfile);
      };
      case null {};
    };

    gameId;
  };

  public query func getGame(gameId : Nat) : async ?Game {
    textMap.get(games, Nat.toText(gameId));
  };

  public query func getAllGames() : async [Game] {
    Iter.toArray(textMap.vals(games));
  };

  public query func getPlayerStats(playerName : Text) : async ?Player {
    textMap.get(playerStats, playerName);
  };

  public query func getAllPlayerStats() : async [Player] {
    Iter.toArray(textMap.vals(playerStats));
  };

  public query func getLeaderboard() : async [Player] {
    var players = Iter.toArray(textMap.vals(playerStats));
    players := Array.sort(
      players,
      func(a : Player, b : Player) : { #less; #equal; #greater } {
        if (a.averageScore > b.averageScore) { #less } else if (a.averageScore < b.averageScore) {
          #greater;
        } else { #equal };
      },
    );
    players;
  };

  public func sendMessage(sender : Text, message : Text, gameId : Nat) : async () {
    let chatMessage : ChatMessage = {
      sender;
      message;
      timestamp = Time.now();
      gameId;
    };
    chatMessages := Array.append(chatMessages, [chatMessage]);
  };

  public query func getMessages(gameId : Nat) : async [ChatMessage] {
    Array.filter(
      chatMessages,
      func(msg : ChatMessage) : Bool {
        msg.gameId == gameId;
      },
    );
  };

  public query func getAllMessages() : async [ChatMessage] {
    chatMessages;
  };

  public query func getAllUserProfiles() : async [UserProfile] {
    Iter.toArray(principalMap.vals(userProfiles));
  };

  public shared ({ caller }) func updateCallerAchievements(achievements : [Text]) : async () {
    switch (principalMap.get(userProfiles, caller)) {
      case (?profile) {
        let updatedProfile : UserProfile = {
          profile with achievements
        };
        userProfiles := principalMap.put(userProfiles, caller, updatedProfile);
      };
      case null {};
    };
  };

  public func updatePlayerStats(name : Text, totalSpares : Nat, totalStrikes : Nat, totalPoints : Nat, highestScore : Nat, gamesPlayed : Nat) : async () {
    switch (textMap.get(playerStats, name)) {
      case (?player) {
        let updatedPlayer : Player = {
          player with totalSpares;
          totalStrikes;
          totalPoints;
          highestScore;
          gamesPlayed;
        };
        playerStats := textMap.put(playerStats, name, updatedPlayer);
      };
      case null {};
    };
  };

  public shared ({ caller }) func updateCallerUserProfileStats(totalSpares : Nat, totalStrikes : Nat, totalPoints : Nat, highestScore : Nat, gamesPlayed : Nat) : async () {
    switch (principalMap.get(userProfiles, caller)) {
      case (?profile) {
        let updatedProfile : UserProfile = {
          profile with totalSpares;
          totalStrikes;
          totalPoints;
          highestScore;
          gamesPlayed;
        };
        userProfiles := principalMap.put(userProfiles, caller, updatedProfile);
      };
      case null {};
    };
  };

  public shared ({ caller }) func registerFileReference(path : Text, hash : Text) : async () {
    Registry.add(registry, path, hash);
  };

  public query ({ caller }) func getFileReference(path : Text) : async Registry.FileReference {
    Registry.get(registry, path);
  };

  public query ({ caller }) func listFileReferences() : async [Registry.FileReference] {
    Registry.list(registry);
  };

  public shared ({ caller }) func dropFileReference(path : Text) : async () {
    Registry.remove(registry, path);
  };

  public shared ({ caller }) func updateCallerProfilePicture(picturePath : Text) : async () {
    switch (principalMap.get(userProfiles, caller)) {
      case (?profile) {
        let updatedProfile : UserProfile = {
          profile with profilePicture = ?picturePath
        };
        userProfiles := principalMap.put(userProfiles, caller, updatedProfile);
      };
      case null {};
    };
  };

  public func createTeam(name : Text, description : Text, creator : Principal) : async Nat {
    let teamId = nextTeamId;
    nextTeamId += 1;

    let team : Team = {
      id = teamId;
      name;
      description;
      creator;
      members = [creator];
      averageScore = 0;
      totalGames = 0;
      bestScore = 0;
      createdAt = Time.now();
    };

    teams := natMap.put(teams, teamId, team);
    teamId;
  };

  public func requestToJoinTeam(teamId : Nat, requester : Principal) : async () {
    let joinRequest : JoinRequest = {
      teamId;
      requester;
      timestamp = Time.now();
    };
    joinRequests := Array.append(joinRequests, [joinRequest]);
  };

  public func approveJoinRequest(teamId : Nat, requester : Principal, approver : Principal) : async () {
    switch (natMap.get(teams, teamId)) {
      case (?team) {
        if (team.creator != approver) {
          Debug.trap("Unauthorized: Only the team creator can approve join requests");
        };

        let updatedMembers = Array.append(team.members, [requester]);
        let updatedTeam : Team = {
          team with members = updatedMembers
        };
        teams := natMap.put(teams, teamId, updatedTeam);

        joinRequests := Array.filter(
          joinRequests,
          func(req : JoinRequest) : Bool {
            not (req.teamId == teamId and req.requester == requester)
          },
        );
      };
      case null {};
    };
  };

  public func denyJoinRequest(teamId : Nat, requester : Principal, denier : Principal) : async () {
    switch (natMap.get(teams, teamId)) {
      case (?team) {
        if (team.creator != denier) {
          Debug.trap("Unauthorized: Only the team creator can deny join requests");
        };

        joinRequests := Array.filter(
          joinRequests,
          func(req : JoinRequest) : Bool {
            not (req.teamId == teamId and req.requester == requester)
          },
        );
      };
      case null {};
    };
  };

  public func inviteToTeam(teamId : Nat, invitee : Principal, inviter : Principal) : async () {
    switch (natMap.get(teams, teamId)) {
      case (?team) {
        if (team.creator != inviter) {
          Debug.trap("Unauthorized: Only the team creator can invite members");
        };

        let invitation : Invitation = {
          teamId;
          invitee;
          inviter;
          timestamp = Time.now();
        };
        invitations := Array.append(invitations, [invitation]);
      };
      case null {};
    };
  };

  public func acceptInvitation(teamId : Nat, invitee : Principal) : async () {
    switch (natMap.get(teams, teamId)) {
      case (?team) {
        let updatedMembers = Array.append(team.members, [invitee]);
        let updatedTeam : Team = {
          team with members = updatedMembers
        };
        teams := natMap.put(teams, teamId, updatedTeam);

        invitations := Array.filter(
          invitations,
          func(inv : Invitation) : Bool {
            not (inv.teamId == teamId and inv.invitee == invitee)
          },
        );
      };
      case null {};
    };
  };

  public func declineInvitation(teamId : Nat, invitee : Principal) : async () {
    invitations := Array.filter(
      invitations,
      func(inv : Invitation) : Bool {
        not (inv.teamId == teamId and inv.invitee == invitee)
      },
    );
  };

  public func leaveTeam(teamId : Nat, member : Principal) : async () {
    switch (natMap.get(teams, teamId)) {
      case (?team) {
        let updatedMembers = Array.filter(
          team.members,
          func(m : Principal) : Bool {
            m != member;
          },
        );
        let updatedTeam : Team = {
          team with members = updatedMembers
        };
        teams := natMap.put(teams, teamId, updatedTeam);
      };
      case null {};
    };
  };

  public query func getTeam(teamId : Nat) : async ?Team {
    natMap.get(teams, teamId);
  };

  public query func getAllTeams() : async [Team] {
    Iter.toArray(natMap.vals(teams));
  };

  public query func getJoinRequests() : async [JoinRequest] {
    joinRequests;
  };

  public query func getInvitations() : async [Invitation] {
    invitations;
  };

  public func updateTeamStats(teamId : Nat, averageScore : Nat, totalGames : Nat, bestScore : Nat) : async () {
    switch (natMap.get(teams, teamId)) {
      case (?team) {
        let updatedTeam : Team = {
          team with averageScore;
          totalGames;
          bestScore;
        };
        teams := natMap.put(teams, teamId, updatedTeam);
      };
      case null {};
    };
  };

  public func getTokenPools() : async [TokenPool] {
    initializeTokenPools(); // Ensure pools are initialized before returning
    Iter.toArray(textMap.vals(tokenPools));
  };

  public func getTokenPool(name : Text) : async ?TokenPool {
    initializeTokenPools(); // Ensure pools are initialized before returning
    textMap.get(tokenPools, name);
  };

  public func updateTokenPool(name : Text, remaining : Nat) : async () {
    switch (textMap.get(tokenPools, name)) {
      case (?pool) {
        let updatedPool : TokenPool = {
          pool with remaining
        };
        tokenPools := textMap.put(tokenPools, name, updatedPool);
      };
      case null {};
    };
  };

  public func recordTokenTransaction(from : ?Principal, to : ?Principal, amount : Nat, transactionType : Text, pool : ?Text, status : Text, reference : ?Text) : async Nat {
    let transactionId = nextTransactionId;
    nextTransactionId += 1;

    let transaction : TokenTransaction = {
      id = transactionId;
      from;
      to;
      amount;
      timestamp = Time.now();
      transactionType;
      pool;
      status;
      reference;
    };

    tokenTransactions := natMap.put(tokenTransactions, transactionId, transaction);
    transactionId;
  };

  public func getTokenTransactions() : async [TokenTransaction] {
    Iter.toArray(natMap.vals(tokenTransactions));
  };

  public func getTokenTransaction(id : Nat) : async ?TokenTransaction {
    natMap.get(tokenTransactions, id);
  };

  public func recordPaymentTransaction(user : Principal, icpAmount : Nat64, exchangeRate : Nat, status : Text, reference : ?Text) : async Nat {
    let paymentId = nextPaymentId;
    nextPaymentId += 1;

    let stkAmount = Nat64.toNat(icpAmount) * exchangeRate;

    let payment : PaymentTransaction = {
      id = paymentId;
      user;
      icpAmount;
      stkAmount;
      exchangeRate;
      timestamp = Time.now();
      status;
      reference;
    };

    paymentTransactions := natMap.put(paymentTransactions, paymentId, payment);

    // Update user balance
    let currentBalance = switch (principalMap.get(userBalances, user)) {
      case (?balance) balance;
      case null 0;
    };
    userBalances := principalMap.put(userBalances, user, currentBalance + stkAmount);

    // Credit user's wallet
    await creditUserWallet(user, stkAmount);

    // Decrement Minting Platform pool
    switch (textMap.get(tokenPools, "Minting Platform")) {
      case (?pool) {
        let updatedPool : TokenPool = {
          pool with remaining = safeSub(pool.remaining, stkAmount)
        };
        tokenPools := textMap.put(tokenPools, "Minting Platform", updatedPool);
      };
      case null {};
    };

    paymentId;
  };

  public func creditUserWallet(user : Principal, stkAmount : Nat) : async () {
    switch (principalMap.get(userWallets, user)) {
      case (?wallet) {
        let updatedWallet : Wallet = {
          wallet with stkBalance = wallet.stkBalance + stkAmount
        };
        userWallets := principalMap.put(userWallets, user, updatedWallet);
      };
      case null {};
    };
  };

  public func getPaymentTransactions() : async [PaymentTransaction] {
    Iter.toArray(natMap.vals(paymentTransactions));
  };

  public func getPaymentTransaction(id : Nat) : async ?PaymentTransaction {
    natMap.get(paymentTransactions, id);
  };

  public func updatePriceFeed(source : Text, icpUsd : Nat, status : Text) : async () {
    let feed : PriceFeed = {
      source;
      icpUsd;
      lastUpdated = Time.now();
      status;
    };
    priceFeeds := textMap.put(priceFeeds, source, feed);
  };

  public func getPriceFeeds() : async [PriceFeed] {
    Iter.toArray(textMap.vals(priceFeeds));
  };

  public func getPriceFeed(source : Text) : async ?PriceFeed {
    textMap.get(priceFeeds, source);
  };

  public func updateUserBalance(user : Principal, amount : Nat) : async () {
    userBalances := principalMap.put(userBalances, user, amount);
  };

  public func getUserBalance(user : Principal) : async Nat {
    switch (principalMap.get(userBalances, user)) {
      case (?balance) balance;
      case null 0;
    };
  };

  public func getTotalSupply() : async Nat {
    totalSupply;
  };

  public func updateTotalSupply(amount : Nat) : async () {
    totalSupply := amount;
  };

  public query func transform(input : OutCall.TransformationInput) : async OutCall.TransformationOutput {
    OutCall.transform(input);
  };

  public func fetchIcpPrice(source : Text) : async Text {
    let url = switch (source) {
      case "coingecko" "https://api.coingecko.com/api/v3/simple/price?ids=internet-computer&vs_currencies=usd";
      case "coinmarketcap" "https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest?symbol=ICP&convert=USD";
      case "binance" "https://api.binance.com/api/v3/ticker/price?symbol=ICPUSDT";
      case "coinbase" "https://api.coinbase.com/v2/prices/ICP-USD/spot";
      case "kraken" "https://api.kraken.com/0/public/Ticker?pair=ICPUSD";
      case _ "https://api.coingecko.com/api/v3/simple/price?ids=internet-computer&vs_currencies=usd";
    };
    await OutCall.httpGetRequest(url, [], transform);
  };

  // Admin Pool Management Functions

  public shared ({ caller }) func transferTokensBetweenPools(sourcePool : Text, destinationPool : Text, amount : Nat) : async () {
    if (not (AccessControl.hasPermission(accessControlState, caller, #admin))) {
      Debug.trap("Unauthorized: Only admins can perform this action");
    };

    initializeTokenPools(); // Ensure pools are initialized

    let source = textMap.get(tokenPools, sourcePool);
    let destination = textMap.get(tokenPools, destinationPool);

    switch (source, destination) {
      case (?src, ?dest) {
        if (src.remaining < amount) {
          Debug.trap("Insufficient balance in source pool");
        };

        let updatedSource : TokenPool = {
          src with remaining = safeSub(src.remaining, amount)
        };

        let updatedDestination : TokenPool = {
          dest with remaining = dest.remaining + amount
        };

        tokenPools := textMap.put(tokenPools, sourcePool, updatedSource);
        tokenPools := textMap.put(tokenPools, destinationPool, updatedDestination);

        let transactionId = nextTransactionId;
        nextTransactionId += 1;

        let transaction : TokenTransaction = {
          id = transactionId;
          from = null;
          to = null;
          amount;
          timestamp = Time.now();
          transactionType = "Pool Transfer";
          pool = ?sourcePool;
          status = "Completed";
          reference = ?("Transferred to " # destinationPool);
        };

        tokenTransactions := natMap.put(tokenTransactions, transactionId, transaction);
      };
      case (null, _) {
        Debug.trap("Source pool not found");
      };
      case (_, null) {
        Debug.trap("Destination pool not found");
      };
    };
  };

  public shared ({ caller }) func adjustPoolAllocation(poolName : Text, newTotal : Nat) : async () {
    if (not (AccessControl.hasPermission(accessControlState, caller, #admin))) {
      Debug.trap("Unauthorized: Only admins can perform this action");
    };

    initializeTokenPools(); // Ensure pools are initialized

    switch (textMap.get(tokenPools, poolName)) {
      case (?pool) {
        let difference = if (newTotal > pool.total) newTotal - pool.total else pool.total - newTotal;
        let updatedRemaining = if (newTotal > pool.total) {
          let result = pool.remaining + difference;
          if (result < pool.remaining) {
            Debug.trap("Overflow detected");
          };
          result;
        } else {
          safeSub(pool.remaining, difference);
        };
        let updatedPool : TokenPool = {
          pool with total = newTotal;
          remaining = updatedRemaining;
        };
        tokenPools := textMap.put(tokenPools, poolName, updatedPool);

        let transactionId = nextTransactionId;
        nextTransactionId += 1;

        let transaction : TokenTransaction = {
          id = transactionId;
          from = null;
          to = null;
          amount = difference;
          timestamp = Time.now();
          transactionType = "Pool Adjustment";
          pool = ?poolName;
          status = "Completed";
          reference = ?("Adjusted total to " # Nat.toText(newTotal));
        };

        tokenTransactions := natMap.put(tokenTransactions, transactionId, transaction);
      };
      case null {
        Debug.trap("Pool not found");
      };
    };
  };

  public query ({ caller }) func getAdminAuditTrail() : async [TokenTransaction] {
    if (not (AccessControl.hasPermission(accessControlState, caller, #admin))) {
      Debug.trap("Unauthorized: Only admins can perform this action");
    };

    var transactions = Iter.toArray(natMap.vals(tokenTransactions));
    transactions := Array.sort(
      transactions,
      func(a : TokenTransaction, b : TokenTransaction) : { #less; #equal; #greater } {
        if (a.timestamp > b.timestamp) { #less } else if (a.timestamp < b.timestamp) {
          #greater;
        } else { #equal };
      },
    );
    transactions;
  };

  public query ({ caller }) func getPoolManagementHistory() : async [TokenTransaction] {
    if (not (AccessControl.hasPermission(accessControlState, caller, #admin))) {
      Debug.trap("Unauthorized: Only admins can perform this action");
    };

    let filtered = Array.filter(
      Iter.toArray(natMap.vals(tokenTransactions)),
      func(tx : TokenTransaction) : Bool {
        tx.transactionType == "Pool Transfer" or tx.transactionType == "Pool Adjustment";
      },
    );
    Array.sort(
      filtered,
      func(a : TokenTransaction, b : TokenTransaction) : { #less; #equal; #greater } {
        if (a.timestamp > b.timestamp) { #less } else if (a.timestamp < b.timestamp) {
          #greater;
        } else { #equal };
      },
    );
  };

  public query ({ caller }) func getRealTimePoolBalances() : async [TokenPool] {
    if (not (AccessControl.hasPermission(accessControlState, caller, #admin))) {
      Debug.trap("Unauthorized: Only admins can perform this action");
    };

    initializeTokenPools(); // Ensure pools are initialized
    Iter.toArray(textMap.vals(tokenPools));
  };

  public query ({ caller }) func getTotalSupplyStatus() : async Nat {
    if (not (AccessControl.hasPermission(accessControlState, caller, #admin))) {
      Debug.trap("Unauthorized: Only admins can perform this action");
    };

    totalSupply;
  };

  // Wallet Management Functions

  public shared ({ caller }) func initializeWallet(icpAccountId : Text, stkPrincipalId : Text) : async () {
    switch (principalMap.get(userWallets, caller)) {
      case (?existingWallet) {
        Debug.trap("Wallet already exists");
      };
      case null {
        let wallet : Wallet = {
          stkBalance = 0;
          icpTransactions = [];
          stkTransactions = [];
          icpAccountId;
          stkPrincipalId;
        };
        userWallets := principalMap.put(userWallets, caller, wallet);
      };
    };
  };

  public query ({ caller }) func getCallerWallet() : async ?Wallet {
    principalMap.get(userWallets, caller);
  };

  public query func getWallet(user : Principal) : async ?Wallet {
    principalMap.get(userWallets, user);
  };

  public shared ({ caller }) func updateCallerWallet(stkBalance : Nat) : async () {
    switch (principalMap.get(userWallets, caller)) {
      case (?wallet) {
        let updatedWallet : Wallet = {
          wallet with stkBalance
        };
        userWallets := principalMap.put(userWallets, caller, updatedWallet);
      };
      case null {
        Debug.trap("Wallet not found");
      };
    };
  };

  public shared ({ caller }) func addIcpTransaction(transaction : TokenTransaction) : async () {
    switch (principalMap.get(userWallets, caller)) {
      case (?wallet) {
        let updatedWallet : Wallet = {
          wallet with icpTransactions = Array.append(wallet.icpTransactions, [transaction])
        };
        userWallets := principalMap.put(userWallets, caller, updatedWallet);
      };
      case null {
        Debug.trap("Wallet not found");
      };
    };
  };

  public shared ({ caller }) func addStkTransaction(transaction : TokenTransaction) : async () {
    switch (principalMap.get(userWallets, caller)) {
      case (?wallet) {
        let updatedWallet : Wallet = {
          wallet with stkTransactions = Array.append(wallet.stkTransactions, [transaction])
        };
        userWallets := principalMap.put(userWallets, caller, updatedWallet);
      };
      case null {
        Debug.trap("Wallet not found");
      };
    };
  };

  public shared ({ caller }) func getCallerIcpBalance(accountId : Blob) : async Result<Nat64, Text> {
    let ledger : Ledger = actor ("ryjl3-tyaaa-aaaaa-aaaba-cai");

    if (accountId.size() != 32) {
      return #err("Invalid account ID size: " # Nat.toText(accountId.size()) # " bytes. Expected 32 bytes.");
    };

    try {
      let balance = await ledger.account_balance({ account = accountId });
      #ok(balance.e8s);
    } catch (_) {
      #err("Error fetching ICP balance");
    };
  };

  public query ({ caller }) func getCallerStkBalance() : async Nat {
    switch (principalMap.get(userWallets, caller)) {
      case (?wallet) wallet.stkBalance;
      case null 0;
    };
  };

  public query ({ caller }) func getCallerIcpTransactions() : async [TokenTransaction] {
    switch (principalMap.get(userWallets, caller)) {
      case (?wallet) wallet.icpTransactions;
      case null [];
    };
  };

  public query ({ caller }) func getCallerStkTransactions() : async [TokenTransaction] {
    switch (principalMap.get(userWallets, caller)) {
      case (?wallet) wallet.stkTransactions;
      case null [];
    };
  };

  public query ({ caller }) func getCallerAddresses() : async (Text, Text) {
    switch (principalMap.get(userWallets, caller)) {
      case (?wallet) (wallet.icpAccountId, wallet.stkPrincipalId);
      case null ("", "");
    };
  };

  public query ({ caller }) func getCallerAccountIds() : async (Text, Text) {
    switch (principalMap.get(userWallets, caller)) {
      case (?wallet) (wallet.icpAccountId, wallet.stkPrincipalId);
      case null ("", "");
    };
  };

  public query ({ caller }) func getCallerPrincipalId() : async Text {
    Principal.toText(caller);
  };

  public shared ({ caller }) func sendIcpTokens(recipient : Text, amount : Nat64, fromAccountId : Blob, toAccountId : Blob) : async Result<Nat64, Text> {
    let ledger : Ledger = actor ("ryjl3-tyaaa-aaaaa-aaaba-cai");

    if (fromAccountId.size() != 32 or toAccountId.size() != 32) {
      return #err("Invalid account ID size. From: " # Nat.toText(fromAccountId.size()) # " bytes, To: " # Nat.toText(toAccountId.size()) # " bytes. Expected 32 bytes each.");
    };

    try {
      let transferResult = await ledger.transfer({
        memo = 0;
        amount = { e8s = amount };
        fee = { e8s = 10000 };
        from_subaccount = null;
        to = toAccountId;
        created_at_time = null;
      });

      let transactionId = nextTransactionId;
      nextTransactionId += 1;

      let transaction : TokenTransaction = {
        id = transactionId;
        from = ?caller;
        to = null;
        amount = Nat64.toNat(amount);
        timestamp = Time.now();
        transactionType = "Send";
        pool = null;
        status = "Completed";
        reference = ?recipient;
      };

      switch (principalMap.get(userWallets, caller)) {
        case (?wallet) {
          let updatedWallet : Wallet = {
            wallet with icpTransactions = Array.append(wallet.icpTransactions, [transaction])
          };
          userWallets := principalMap.put(userWallets, caller, updatedWallet);
        };
        case null {};
      };

      #ok(transferResult.height);
    } catch (_) {
      #err("Error sending ICP tokens");
    };
  };

  public shared ({ caller }) func sendStkTokens(recipient : Text, amount : Nat) : async () {
    switch (principalMap.get(userWallets, caller)) {
      case (?wallet) {
        if (wallet.stkBalance < amount) {
          Debug.trap("Insufficient STK balance");
        };

        let transactionId = nextTransactionId;
        nextTransactionId += 1;

        let transaction : TokenTransaction = {
          id = transactionId;
          from = ?caller;
          to = null;
          amount;
          timestamp = Time.now();
          transactionType = "Send";
          pool = null;
          status = "Pending";
          reference = ?recipient;
        };

        let updatedWallet : Wallet = {
          wallet with stkBalance = safeSub(wallet.stkBalance, amount);
          stkTransactions = Array.append(wallet.stkTransactions, [transaction]);
        };
        userWallets := principalMap.put(userWallets, caller, updatedWallet);
      };
      case null {
        Debug.trap("Wallet not found");
      };
    };
  };

  public shared ({ caller }) func receiveStkTokens(amount : Nat) : async () {
    switch (principalMap.get(userWallets, caller)) {
      case (?wallet) {
        let transactionId = nextTransactionId;
        nextTransactionId += 1;

        let transaction : TokenTransaction = {
          id = transactionId;
          from = null;
          to = ?caller;
          amount;
          timestamp = Time.now();
          transactionType = "Receive";
          pool = null;
          status = "Completed";
          reference = null;
        };

        let updatedWallet : Wallet = {
          wallet with stkBalance = wallet.stkBalance + amount;
          stkTransactions = Array.append(wallet.stkTransactions, [transaction]);
        };
        userWallets := principalMap.put(userWallets, caller, updatedWallet);
      };
      case null {
        Debug.trap("Wallet not found");
      };
    };
  };

  public query ({ caller }) func getCallerWalletSummary() : async (Nat, [TokenTransaction], [TokenTransaction], Text, Text) {
    switch (principalMap.get(userWallets, caller)) {
      case (?wallet) {
        (
          wallet.stkBalance,
          wallet.icpTransactions,
          wallet.stkTransactions,
          wallet.icpAccountId,
          wallet.stkPrincipalId,
        );
      };
      case null (0, [], [], "", "");
    };
  };

  public shared func verifyIcpPayment(accountId : Blob) : async Result<Nat64, Text> {
    let ledger : Ledger = actor ("ryjl3-tyaaa-aaaaa-aaaba-cai");

    if (accountId.size() != 32) {
      return #err("Invalid account ID size: " # Nat.toText(accountId.size()) # " bytes. Expected 32 bytes.");
    };

    try {
      let balance = await ledger.account_balance({ account = accountId });
      #ok(balance.e8s);
    } catch (_) {
      #err("Error verifying ICP payment");
    };
  };

  public shared ({ caller }) func mintStkTokens(icpAmount : Nat64, stkAmount : Nat, exchangeRate : Nat, accountId : Blob) : async Result<(), Text> {
    let ledger : Ledger = actor ("ryjl3-tyaaa-aaaaa-aaaba-cai");

    if (accountId.size() != 32) {
      return #err("Invalid account ID size: " # Nat.toText(accountId.size()) # " bytes. Expected 32 bytes.");
    };

    try {
      let balance = await ledger.account_balance({ account = accountId });

      if (balance.e8s < icpAmount) {
        return #err("Insufficient ICP balance. Required: " # Nat64.toText(icpAmount) # ", Available: " # Nat64.toText(balance.e8s));
      };

      switch (principalMap.get(userWallets, caller)) {
        case (?wallet) {
          let icpTransactionId = nextTransactionId;
          nextTransactionId += 1;

          let icpTransaction : TokenTransaction = {
            id = icpTransactionId;
            from = ?caller;
            to = null;
            amount = Nat64.toNat(icpAmount);
            timestamp = Time.now();
            transactionType = "ICP Payment";
            pool = null;
            status = "Completed";
            reference = ?("STK mint: " # Nat.toText(stkAmount));
          };

          let updatedWallet : Wallet = {
            wallet with icpTransactions = Array.append(wallet.icpTransactions, [icpTransaction])
          };
          userWallets := principalMap.put(userWallets, caller, updatedWallet);

          let stkTransactionId = nextTransactionId;
          nextTransactionId += 1;

          let stkTransaction : TokenTransaction = {
            id = stkTransactionId;
            from = null;
            to = ?caller;
            amount = stkAmount;
            timestamp = Time.now();
            transactionType = "Mint";
            pool = ?("Minting Platform");
            status = "Completed";
            reference = ?("ICP payment: " # Nat64.toText(icpAmount));
          };

          tokenTransactions := natMap.put(tokenTransactions, stkTransactionId, stkTransaction);

          let paymentId = nextPaymentId;
          nextPaymentId += 1;

          let payment : PaymentTransaction = {
            id = paymentId;
            user = caller;
            icpAmount;
            stkAmount;
            exchangeRate;
            timestamp = Time.now();
            status = "Completed";
            reference = ?("ICP payment: " # Nat64.toText(icpAmount));
          };

          paymentTransactions := natMap.put(paymentTransactions, paymentId, payment);

          #ok(());
        };
        case null {
          #err("Wallet not found");
        };
      };
    } catch (_) {
      #err("Error verifying ICP payment");
    };
  };

  include BlobStorage(registry);
};

