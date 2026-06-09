---@meta

---MySQLOO - Garry's Mod MySQL module by FredyH
---@see https://github.com/FredyH/MySQLOO

---@class mysqloo
---@field VERSION string Current MySQLOO version (e.g. "9")
---@field MINOR_VERSION string Minor version of this library
---@field DATABASE_CONNECTED number Database is connected
---@field DATABASE_NOT_CONNECTED number Database is not connected
---@field DATABASE_INTERNAL_ERROR number Internal error
---@field QUERY_NOT_RUNNING number Query not running
---@field QUERY_WAITING number Query is queued/started
---@field QUERY_RUNNING number Query is being processed on the database server
---@field QUERY_COMPLETE number Query is complete
---@field QUERY_ABORTED number Query was aborted
---@field OPTION_NUMERIC_FIELDS number Use numeric (indexed) field keys instead of field names
---@field OPTION_NAMED_FIELDS number Use named field keys (default)
---@field OPTION_INTERPRET_DATA number Interpret returned data as their corresponding Lua types (default)
---@field OPTION_CACHE number Enable query result caching
mysqloo = {}

---Initializes a Database object. Does not actually connect to the database.
---@param host string MySQL server hostname or IP
---@param username string MySQL username
---@param password string MySQL password
---@param database string Database name to use
---@param port? number MySQL server port (default: 3306)
---@param socket? string Unix socket path for local connections
---@return Database db The database object (call db:connect() to establish connection)
function mysqloo.connect(host, username, password, database, port, socket) end

-- =============================================================================
-- Database
-- =============================================================================

---@class Database
---A MySQLOO database connection object.
---Created via mysqloo.connect(). Call :connect() to establish the connection.
local Database = {}

---Connects to the database asynchronously.
---Calls onConnected or onConnectionFailed callback when done.
function Database:connect() end

---Disconnects from the database.
---@param shouldWait? boolean If true, waits for all queued queries to finish before disconnecting
function Database:disconnect(shouldWait) end

---Creates a query associated with this database.
---@param sql string SQL query string to execute
---@return Query query The query object
function Database:query(sql) end

---Creates a prepared query associated with this database.
---@param sql string Parameterized SQL query string (use ? as placeholders)
---@return PreparedQuery query The prepared query object
function Database:prepare(sql) end

---Creates a transaction that executes multiple statements atomically.
---@return Transaction transaction The transaction object
function Database:createTransaction() end

---Escapes a string for safe use in a query.
---@param str string The string to escape
---@return string escaped The escaped string
function Database:escape(str) end

---Aborts all waiting (QUERY_WAITING) queries.
---@return number aborted The number of queries aborted
function Database:abortAllQueries() end

---Blocks until the database connection is established or fails.
function Database:wait() end

---Returns the current connection status.
---@return number status One of mysqloo.DATABASE_* enums
function Database:status() end

---Pings the database server asynchronously.
---Calls the onSuccess or onError callback of the returned query-like object.
---@return Query pingQuery A query-like object representing the ping
function Database:ping() end

---Returns the number of queries currently in the queue.
---@return number size Queue size
function Database:queueSize() end

---Returns the MySQL server version as a number.
---@return number version Server version number
function Database:serverVersion() end

---Returns the MySQL server version as a string.
---@return string info Server version info
function Database:serverInfo() end

---Returns host connection information.
---@return string info Host info string
function Database:hostInfo() end

---Sets the character set for the connection.
---@param charset string Character set name (e.g. "utf8mb4")
function Database:setCharacterSet(charset) end

---Enables or disables automatic reconnection.
---Must be called before Database:connect().
---@param shouldReconnect boolean Whether to auto-reconnect on connection loss
function Database:setAutoReconnect(shouldReconnect) end

---Enables or disables multi-statement support.
---Must be called before Database:connect().
---@param useMultiStatements boolean Whether to allow multiple statements in one query
function Database:setMultiStatements(useMultiStatements) end

---Enables or disables caching of prepared statement handles.
---Must be called before Database:connect().
---@param cachePreparedStatements boolean Whether to cache prepared statements
function Database:setCachePreparedStatements(cachePreparedStatements) end

---Sets the read timeout for the connection.
---Must be called before Database:connect().
---@param timeout number Timeout in seconds
function Database:setReadTimeout(timeout) end

---Sets the write timeout for the connection.
---Must be called before Database:connect().
---@param timeout number Timeout in seconds
function Database:setWriteTimeout(timeout) end

---Sets the connect timeout for the connection.
---Must be called before Database:connect().
---@param timeout number Timeout in seconds
function Database:setConnectTimeout(timeout) end

---Sets the SSL mode for the connection.
---Must be called before Database:connect().
---@param sslMode number SSL mode constant
function Database:setSSLMode(sslMode) end

---Sets SSL connection parameters.
---Must be called before Database:connect().
---@param key string Path to the client private key file
---@param cert string Path to the client certificate file
---@param ca string Path to the CA certificate file
---@param capath string Path to a directory of trusted CA certificates
---@param cipher string List of allowed ciphers
function Database:setSSLSettings(key, cert, ca, capath, cipher) end

---Called when the connection to the MySQL server succeeds.
---Override this callback on your database instance.
---@type fun(self: Database)
Database.onConnected = nil

---Called when the connection to the MySQL server fails.
---Override this callback on your database instance.
---@type fun(self: Database, err: string)
Database.onConnectionFailed = nil

---Called after disconnect() completes and all queries have finished.
---Must be set before calling Database:connect().
---@type fun(self: Database)
Database.onDisconnected = nil

-- =============================================================================
-- Query
-- =============================================================================

---@class Query
---A MySQLOO query object.
---Created via Database:query(). Call :start() to execute.
local Query = {}

---Starts the query asynchronously.
function Query:start() end

---Returns whether the query is currently running or waiting.
---@return boolean running True if the query is running or waiting
function Query:isRunning() end

---Returns the data the query returned from the server.
---Format: { row1, row2, ... } where each row is { field_name = field_value }.
---Returns nil if the query errored or was aborted.
---@return table<number, table<string, any>>|nil data Result rows
function Query:getData() end

---Attempts to abort the query if it is still in the QUERY_WAITING state.
---@return boolean aborted True if the query was successfully aborted
function Query:abort() end

---Returns the last auto-increment insert ID, or 0 if not applicable.
---@return number insertId The last insert ID
function Query:lastInsert() end

---Returns the number of rows affected by INSERT/DELETE/UPDATE,
---or the number of rows returned by SELECT.
---@return number affected Number of affected/returned rows
function Query:affectedRows() end

---Returns whether there are additional result sets remaining.
---Only relevant when using multi-statement queries.
---@return boolean hasMore True if more result sets are available
function Query:hasMoreResults() end

---Moves to the next result set (for multi-statement queries).
---After calling this, getData() returns the next result set.
function Query:getNextResults() end

---Returns the error message of the query, or empty string if no error.
---@return string err Error message
function Query:error() end

---Sets a query option (e.g. OPTION_NUMERIC_FIELDS).
---@param option number One of mysqloo.OPTION_* constants
---@param enabled boolean Whether to enable or disable the option
function Query:setOption(option, enabled) end

---Blocks the main thread until the query finishes.
---Should only be used during server startup/initialization.
function Query:wait() end

---Called when the query completes successfully.
---Override this callback on your query instance.
---@type fun(self: Query, data: table<number, table<string, any>>)
Query.onSuccess = nil

---Called when the query encounters an error.
---Override this callback on your query instance.
---@type fun(self: Query, err: string, sql: string)
Query.onError = nil

---Called when a single row is retrieved (streaming mode).
---Override this callback on your query instance.
---@type fun(self: Query, data: table<string, any>)
Query.onData = nil

---Called when the query is aborted.
---Override this callback on your query instance.
---@type fun(self: Query)
Query.onAborted = nil

-- =============================================================================
-- PreparedQuery
-- =============================================================================

---@class PreparedQuery : Query
---A MySQLOO prepared query object.
---Created via Database:prepare(). Uses parameterized queries for safety.
---Inherits all Query methods and callbacks.
local PreparedQuery = {}

---Sets a numeric (double) parameter at the given index.
---@param index number 1-based parameter index
---@param value number The numeric value
function PreparedQuery:setNumber(index, value) end

---Sets a string parameter at the given index.
---The string does NOT need to be escaped.
---@param index number 1-based parameter index
---@param value string The string value
function PreparedQuery:setString(index, value) end

---Sets a boolean parameter at the given index.
---@param index number 1-based parameter index
---@param value boolean The boolean value
function PreparedQuery:setBoolean(index, value) end

---Sets a NULL parameter at the given index.
---@param index number 1-based parameter index
function PreparedQuery:setNull(index) end

---Clears all currently set parameters.
function PreparedQuery:clearParameters() end

---Adds a new set of parameters for batch execution.
---@deprecated Start the same prepared statement multiple times instead.
function PreparedQuery:putNewParameters() end

-- =============================================================================
-- Transaction
-- =============================================================================

---@class Transaction
---A MySQLOO transaction object.
---Created via Database:createTransaction(). Groups multiple queries atomically.
---Either all queries succeed or none have any effect.
local Transaction = {}

---Adds a query to the transaction.
---Individual query callbacks will NOT be called.
---@param query Query|PreparedQuery The query to add
function Transaction:addQuery(query) end

---Returns all queries that have been added to this transaction.
---@return (Query|PreparedQuery)[] queries List of added queries
function Transaction:getQueries() end

---Removes all queries from the transaction.
function Transaction:clearQueries() end

---Starts the transaction asynchronously.
function Transaction:start() end

---Returns whether the transaction is currently running or waiting.
---@return boolean running True if the transaction is running or waiting
function Transaction:isRunning() end

---Returns the error message of the transaction, or empty string if no error.
---@return string err Error message
function Transaction:error() end

---Sets a transaction option.
---@param option number One of mysqloo.OPTION_* constants
---@param enabled boolean Whether to enable or disable the option
function Transaction:setOption(option, enabled) end

---Attempts to abort the transaction if it is still waiting.
---@return boolean aborted True if successfully aborted
function Transaction:abort() end

---Blocks the main thread until the transaction finishes.
function Transaction:wait() end

---Called when all queries in the transaction execute successfully.
---Override this callback on your transaction instance.
---@type fun(self: Transaction)
Transaction.onSuccess = nil

---Called when any query in the transaction causes an error.
---No queries will have had any effect.
---Override this callback on your transaction instance.
---@type fun(self: Transaction, err: string)
Transaction.onError = nil

---Called when the transaction is aborted.
---Override this callback on your transaction instance.
---@type fun(self: Transaction)
Transaction.onAborted = nil
