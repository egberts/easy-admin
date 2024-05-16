
`action.copyMsg`, action, builtin
`action.errorfile`, action, builtin
`action.errorfile.maxsize`, action, builtin
`action.execOnlyEveryNthTime`, action, builtin
`action.execOnlyEveryNthTimeout`, action, builtin
`action.execOnlyOnceEveryInterval`, action, builtin
`action.execOnlyWhenPreviousIsSuspended`, action, builtin
`action.repeatedmsgcontainoriginalmsg`, action, builtin
`action.reportSuspension`, action, builtin
`action.reportSuspensionContinuation`, action, builtin
`action.resumeRetryCount`, action, builtin
`action.resumeRetryInterval`, action, builtin
`action.resumeRetryIntervalMax`, action, builtin
`action.writeAllMarkMessages`, action, builtin
`addCeeTag`, input, imfile, binary, `off`, no, , , , This is used to turn on or off the addition of the "@cee:" cookie to the message object.
`addMetadata`, input, imfile, binary, `-1`, no, , , , This is used to turn on or off the addition of metadata to the message object.
`addmetadata`, input, imhttp, binary, `off`, no, , , , Enables metadata injection into `$!metadata` property. Currently, only header data is supported. 
`address`, action, imdtls, word, , no, , 8.2402.0, , Specifies the IP address on where the imdtls module will listen for incoming syslog messages. By default the module will listen on all available network connections.
`Address`, input, imptcp, string, , no, `$InputPTCPServerListenIP`, , , On multi-homed machines, specifies to which local address the listener should be bound.
`Address`, input, imrelp, string, , no, , 8.37.0, , Bind the RELP server to that address. If not specified, the server will be bound to the wildcard address.
`Address`, input, imtcp, string, , no, , , , On multi-homed machines, specifies to which local address the listener should be bound.
`Address`, input, imudp, string, , no, `$UDPServerAddress`, , , Local IP address (or name) the UDP server should bind to. Use "`*`" to bind to all of the machine's addresses.
`AddtlFrameDelimiter`, input, imptcp, integer, `-1`, no, `$InputPTCPServerAddtlFrameDelimiter`, 4.3.1, , This directive permits to specify an additional frame delimiter for plain tcp syslog. 
`AddtlFrameDelimiter`, input, imtcp, integer, `<module parameter>`, no, , 8.2106.0, , This permits to override the equally-named module parameter on the `input()` level. For further details, see the module parameter.
`AddtlFrameDelimiter`, module, imtcp, integer, `-1`, no, `$InputTCPServerAddtlFrameDelimiter`, 4.3.1, , This directive permits to specify an additional frame delimiter for Multiple receivers may be configured by specifying `$InputTCPServerRun` multiple times.
`Allowed_Error_Codes`, action, ommongodb
`allow_regex`, module, mmnormalize, boolean, `off`, no, , 6.1.2, , Specifies if regex field-type should be allowed. Regex field-type has significantly higher computational overhead compared to other fields, so it should be avoided when another field-type can achieve the desired effect. Needs to be "on" for regex field-type to work.
`allowUnsignedCerts`, action, omclickhouse, binary, `on`, no, , , , The module accepts connections to servers, which have unsigned certificates. If this parameter is disabled, the module will verify whether the certificates are authentic.
`allowunsignedcerts`, action, omelasticsearch, boolean, `off`, no, , , , If "`on`", this will set the curl `CURLOPT_SSL_VERIFYPEER` option to `0`. You are strongly discouraged to set this to "`on`". It is primarily useful only for debugging or testing.
`allowunsignedcerts`, action, omhttp
`allowunsignedcerts`, module, mmkubernetes, boolean, `off`, no, , , , If "on", this will set the curl `CURLOPT_SSL_VERIFYPEER` option to 0. You are strongly discouraged to set this to "`on`". It is primarily useful only for debugging or testing.
`amqp_address`, action, omazureeventhubs, integer, `2000`, no, , 8.2304, , "The configuration property for the AMQP address used to connect to Microsoft Azure Event Hubs is typically referred to as the 'Event Hubs connection string'. It specifies the URL that is used to connect to the target Event Hubs instance in Microsoft Azure. If the `amqp_address` is configured, the configuration parameters for `azurehost`, `azureport`, `azure_key_name` and `azure_key` will be ignored.  A sample Event Hubs connection string URL is: `amqps://[Shared access key name]:[Shared access key]@[Event Hubs namespace].servicebus.windows.net/[Event Hubs Instance]`"
`Annotate`, input, imuxsock, binary, `off`, no, `$InputUnixListenSocketAnnotate`, , , Turn on annotation/trusted properties for the input that is being defined. See the imuxsock-trusted-properties-label section for more info.
`annotation_match`, module, mmkubernetes, array, , no, , , , By default no pod or namespace annotations will be added to the messages. This parameter is an array of patterns to match the keys of the annotations field in the pod and namespace metadata to include in the `$!kubernetes!annotations` (for pod annotations) or the `$!kubernetes!namespace_annotations` (for namespace annotations) message properties. Example: `["k8s.*master","k8s.*node"]`
`ApiVersionStr`, module, imdocker, string, `v1.27`, no, , 8.41.0, , Specifies the Docker unix socket address to use. 
`appname`, action, mmcount, 7.5.0, ,
`asyncrepl`, action, omelasticsearch, binary, `off`, no, , , , No longer supported as ElasticSearch no longer supports it.
`asyncWriting`, action, omfile, binary, `off`, no, `$OMFileSyncWriting`, , , If turned on, the files will be written in asynchronous mode via a separate thread. In that case, double buffers will be used so that one buffer can be filled while the other buffer is being written. Note that in order to enable `FlushInterval`, AsyncWriting must be set to "`on`". Otherwise, the flush interval will be ignored.
`azurehost`, action, omazureeventhubs, word, , yes, , 8.2304, , Specifies the fully qualified domain name (FQDN) of the Event Hubs instance that the rsyslog output plugin should connect to. The format of the hostname should be `<namespace>.servicebus.windows.net`, where `<namespace>` is the name of the Event Hubs namespace that was created in Microsoft Azure. 
`azure_key`, action, omazureeventhubs, word, , yes, , 8.2304, , The configuration property for the Azure key used to connect to Microsoft Azure Event Hubs is typically referred to as the “Event Hubs shared access key”. It specifies the value of the shared access key that is used to authenticate and authorize connections to the Event Hubs instance. The shared access key is a secret string that is used to securely sign and validate requests to the Event Hubs instance.
`azure_key_name`, action, omazureeventhubs, word, , yes, , 8.2304, , The configuration property for the Azure key name used to connect to Microsoft Azure Event Hubs is typically referred to as the “Event Hubs shared access key name”. It specifies the name of the shared access key that is used to authenticate and authorize connections to the Event Hubs instance. The shared access key is a secret string that is used to securely sign and validate requests to the Event Hubs instance.
`azureport`, action, omazureeventhubs, word, `5671`, no, , 8.2304, , Specifies the TCP port number used by the Event Hubs instance for incoming connections. The default port number for Event Hubs is `5671` for connections over the AMQP Secure Sockets Layer (SSL) protocol. This property is usually optional in the configuration file of the rsyslog output plugin, as the default value of `5671` is typically used.
`basicAuthFile`, input, imhttp, string, , no, , , , Configures a `htpasswd` file and enables basic authentication on http request received on this input. If this option is not set, basic authentation will not be enabled.
`batch`, action, omhttp
`batch.format`, action, omhttp
`batch.maxbytes`, action, omhttp
`batch.maxsize`, action, omhttp
`batchsize`, input, imhiredis, number, `10`, yes, , , , Defines the dequeue batch size for redis pipelining.  imhiredis will read "`**batchsize**`" elements from redis at a time.
`BatchSize`, module, imudp, integer, `32`, no, , , , This parameter is only meaningful if the system support recvmmsg() (newer Linux OSs do this). The parameter is silently ignored if the system does not support it. If supported, it sets the maximum number of UDP messages that can be obtained with a single OS call. For systems with high UDP traffic, a relatively high batch size can reduce system overhead and improve performance. However, this parameter should not be overdone. For each buffer, max message size bytes are statically required. Also, a too-high number leads to reduced efficiency, as some structures need to be completely initialized before the OS call is done.
`beginTransactionMark`, action, omprog
`Binary`, action, improg, string, `<external program> [<cmd arguments>]`, yes, , , , Command line : external program and arguments
`binary`, action, mmexternal, string, , yes, , 8.3.0, , The name of the external message modification plugin to be called. This can be a full path name.
`binary`, action, omprog
`Body.Enable`, action, ommail
`body_template`, action, omrabbitmq
`Bracketing`, module, impstats, binary, `off`, no, , , , This is a utility setting for folks who post-process impstats logs and would like to know the begin and end of a block of statistics. When "bracketing" is set to "`on`", impstats issues a "BEGIN" message before the first counter is issued, then all counter values are issued, and then an "END" message follows. 
`Broker`, action, imkafka, array, `localhost:9092`, no, , 8.27.0, , Specifies the broker(s) to use.
`Broker`, action, omkafka
`buffer_size`, input, impcap, number (octets), `15740640`, no, , , , Set a buffer size in bytes to the capture handle. This parameter is only relevant when `no_buffer` is not active, and should be set depending on input packet rates, `buffer_timeout` and `packet_count` values.
`buffer_timeout`, input, impcap, number (ms), `10`, no, , , , Set a timeout in milliseconds between two system calls to get bufferized packets. This parameter prevents low input rate interfaces to keep packets in buffers for too long, but does not guarantee fetch every X seconds.
`bulkid`, action, omelasticsearch, word, , no, , , ,  This is the unique id to assign to the record. The bulk part is misleading - this can be used in both bulk mode `bulkmode` or in index (record at a time) mode. 
`bulkmode`, action, omclickhouse, binary, `on`, no, , , , The "`off`" setting means logs are shipped one by one. Each in its own HTTP request. The default "`on`" will send multiple logs in the same request. This is recommended, because it is many times faster than when bulkmode is turned off. The maximum number of logs sent in a single bulk request depends on your maxbytes and queue settings - usually limited by the dequeue batch size. 
`bulkmode`, action, omelasticsearch, binary, `off`, no, , , , The default "`off`" setting means logs are shipped one by one. Each in its own HTTP request, using the Index API. Set it to "`on`" and it will use Elasticsearch's Bulk API to send multiple logs in the same request.  
`busyretryinterval`, module, mmkubernetes, integer, `5`, no, , , , The number of seconds to wait before retrying operations to the Kubernetes API server after receiving a `429 Busy response`. The default "5" means that the module will retry the connection every 5 seconds. 
`ca_cert`, action, omrabbitmq
`cacheentryttl`, module, mmkubernetes, integer, `3600`, no, , , , This parameter allows you to set the maximum age (time-to-live, or ttl) of an entry in the metadata cache. The value is in seconds. The default value is 3600 (one hour). When cache expiration is checked, if a cache entry has a ttl less than or equal to the current time, it will be removed from the cache.
`cacheexpireinterval`, module, mmkubernetes, integer, `-1`, no, , , , This parameter allows you to expire entries from the metadata cache. The values are -1: (default) - disables metadata cache expiration; 0: check cache for expired entries before every cache lookup; 1 or higher: the number is a number of seconds - check the cache for expired entries every this many seconds, when processing an entry
`checkpath`, action, omhttp
`closeTimeout`, action, improg, number, `200`, no, , , , Specifies whether a `KILL` signal must be sent to the external program in case it does not terminate within the timeout indicated by closeTimeout (when either the worker thread has been unscheduled, a restart of the program is being forced, or rsyslog is about to shutdown).
`closeTimeout`, action, omazureeventhubs, integer, `2000`, no, , 8.2304, , "The close timeout configuration property is used in the rsyslog output module to specify the amount of time the output module should wait for a response from Microsoft Azure Event Hubs before timing out and closing the connection.  This property is used to control the amount of time the output module will wait for a response from the target Event Hubs instance before giving up and assuming that the connection has failed. The close timeout property is specified in milliseconds.
`closeTimeout`, action, omfile, integer, `0`, no, , 8.3.3, , Specifies after how many minutes of inactivity a file is automatically closed.
`closeTimeout`, action, omkafka
`closeTimeout`, action, omprog
`Collection`, action, ommongodb
`commitTransactionMark`, action, omprog
`Community`, action, omsnmp
`compress`, action, omhttp
`compression.driver`, module, omfile, name, `zlib`, no, , 8.2208.0, , For compressed operation ("zlib mode"), this permits to set the compression driver to be used. Originally, only zlib was supported and still is the default. Since 8.2208.0 zstd is also supported. It provides much better compression ratios and performance, especially with multiple zstd worker threads enabled.  Possible values are: `zlib` and `zstd`
`Compression.mode`, input, imptcp, word, , no, , , , This is the counterpart to the compression modes set in omfwd `<omfwd>`. Please see it's documentation for details.
`compression.zstd.workers`, module, omfile, positive integer, , no, , 8.2208.0, , In zstd mode, this enables to configure zstd-internal compression worker threads. This setting has nothing to do with rsyslog workers.
`compress.level`, action, omhttp
`confirmMessages`, action, improg, binary, `on`, no, , , , Specifies whether the external program needs feedback from rsyslog via stdin. When this switch is set to "`on`", rsyslog confirms each received message.
`confirmMessages`, action, omprog
`confirmTimeout`, action, omprog
`ConfParam`, action, imkafka, array, , no, , 8.27.0, , Permits to specify Kafka options. 
`ConfParam`, action, omkafka
`Conninfo`, action, ompgsql
`Conn.Timeout`, action, omrelp
`ConsoleLogLevel`, module, imklog, integer, `-1`, no, `$klogConsoleLogLevel`, , , Sets the console log level. If specified, only messages with up to the specified level are printed to the console. The default is `-1`, which means that the current settings are not modified.
`ConsumerGroup`, action, imkafka, string, , no, , 8.27.0, , With this parameter the `group.id` for the consumer is set. All consumers sharing the same `group.id` belong to the same group.
`container`, action, mmjsonparse, string, `$!`, no, , 6.6.0, , Specifies the JSON container (path) under which parsed elements should be placed. By default, all parsed properties are merged into root of message properties. You can place them under a subtree, instead. You can place them in local variables, also, by setting `path="$."`.
`container`, action, omazureeventhubs, word, , yes, , 8.2304, , The configuration property for the Azure container used to connect to Microsoft Azure Event Hubs is typically referred to as the “Event Hubs Instance”. It specifies the name of the Event Hubs Instance, to which log data should be sent.
`container`, module, mmdblookup, word, `!iplocation`, no, , 8.28, , Specifies the container to be used to store the fields amended by mmdblookup.
`containerrulebase`, module, mmkubernetes, word, `/etc/rsyslog.d/k8s_container_name.rulebase`, no, , , , When processing json-file logs, this is the rulebase used to match the `CONTAINER_NAME` property value and extract metadata. For the actual rules, see containerrules.
`containerrules`, module, mmkubernetes, word, `*`, no, , , , For journald logs, there must be a message property `CONTAINER_NAME` which has a value matching these rules specified by this parameter. The default value is: `rule=:%k8s_prefix:char-to:_%_%container_name:char-to:.%.%container_hash:char-to:_%_%pod_name:char-to:_%_%namespace_name:char-to:_%_%not_used_1:char-to:_%_%not_used_2:rest%rule=:%k8s_prefix:char-to:_%_%container_name:char-to:_%_%pod_name:char-to:_%_%namespace_name:char-to:_%_%not_used_1:char-to:_%_%not_used_2:rest%`
`content_type`, action, omrabbitmq
`cookie`, action, mmjsonparse, string, `@cee:`, no, , 6.6.0, , Permits to set the cookie that must be present in front of the JSON part of the message.
`CreateDirs`, action, omfile, binar, `on`, no, `CreateDirs`, , , Create directories on an as-needed basis
`CreatePath`, input, imuxsock, binary, `off`, no, `$InputUnixListenSocketCreatePath`, 4.7.0, , Create directories in the socket path if they do not already exist. They are created with `0755` permissions with the owner being the process under which rsyslogd runs. The default is not to create directories. 
`cry.Provider`, action, omfile, word, , no, , , , Selects a crypto provider for log encryption. By selecting a provider, the encryption feature is turned on.  Currently, there only is one provider called "`gcry <../cryprov_gcry>`".
`data_container`, module, impcap, word, `!data`, no, , , , Defines the container to place all the data of the network packet. 'data' here defines everything above transport layer in the OSI model, and is a string representation of the hexadecimal values of the stream.
`DB`, action, omlibdbi
`db`, action, ommongodb
`db`, action, ommysql
`db`, action, ompgsql
`declare_exchange`, action, omrabbitmq
`de_dot`, module, mmkubernetes, boolean, `on`, no, , , , When processing labels and annotations, if this parameter is set to "`on`", the key strings will have their . characters replaced with the string specified by the `de_dot_separator` parameter.
`de_dot_separator`, module, mmkubernetes, word, , no, , , , When processing labels and annotations, if the `de_dot` parameter is set to "on", the key strings will have their . characters replaced with the string specified by the string value of this parameter.
`DeduplicateSpaces`, action, imbatchreport, binary, `no`, , on, , , The parameter modify the way consecutive spaces like chars are managed. When it is setted to "`on`", consecutive spaces like chars are reduced to a single one and trailing space like chars are suppressed.
`DefaultFacility`, module, imdocker, integer or string (preferred), `user`, no, `$InputFileFacility`, 8.41.0, , The syslog facility to be assigned to log messages received. Specified as numbers.
`DefaultFacility`, module, imjournal, severity, `5`, no, `$imjournalDefaultFacility`, 7.11.3, , Some messages coming from journald don't have the `SYSLOG_PRIORITY` field. These are typically the messages logged through journald's native API. 
`DefaultNetstreamDriverCAFile`, module, imtcp, string, , no, , , , 
`DefaultNetstreamDriverCertFile`, global, imtcp, string, , no, , , 
`DefaultNetstreamDriverKeyFile`, global, imtcp, string, , no, , , , 
`DefaultSeverity`, module, imdocker, integer or string (preferred), `notice`, no, `$InputFileSeverity`, 8.41.0, , The syslog severity to be assigned to log messages received. Specified as numbers (e.g. 6 for info). Textual form is suggested. Default is `notice`.
`DefaultSeverity`, module, imjournal
`defaultTag`, module, imjournal, binary, `off`, no, , 8.2312.0, , The DefaultTag option specifies the default value for the tag field. In imjournal, this can happen when one of the following is missing: identifier string provided by the application (`SYSLOG_IDENTIFIER`) or name of the process the journal entry originates from (`_COMM`)
`DefaultTemplate`, action, omuxsock
`Defaulttz`, input, imptcp, string, , no, , , , Set default time zone. At most seven chars are set, as we would otherwise overrun our buffer.
`DefaultTZ`, input, imudp, string, , no, , , , This is an experimental parameter; details may change at any time and it may also be discontinued without any early warning. Permits to set a default timezone for this listener. 
`Delete`, action, imbatchreport, string, `<regex><reject>`, no, , , , This parameter informs the module to delete the report to flag it as treated. If the file is too large (or failed to be removed) it is renamed using the `<regex>` to identify part of the file name that has to be replaced it by `<reject>`.
`deleteStateOnFileDelete`, input, imfile, binary, `on`, no, , , , This parameter controls if state files are deleted if their associated main file is deleted. Usually, this is a good idea, because otherwise problems would occur if a new file with the same name is created. 
`delivery_mode`, action, omrabbitmq
`Device`, input, imudp, string, , no, , , , Bind socket to given device (e.g., `eth0`).  For Linux with VRF support, the Device option can be used to specify the VRF for the Address.
`dirCreateMode`, action, omfile, file mode, , no, `$DirCreateMode`, , , This is the same as FileCreateMode, but for directories automatically generated.
`DirCreateMode`, module, omfile, file mode, `O0700`, no, `$DirCreateMode`, , , Sets the default dirCreateMode to be used for an action if no explicit one is specified.
`dirGroup`, action, omfile, file mode, , no, `$DirGroup`, , , Set the group for directories newly created.
`dirGroup`, module, omfile, file mode, , no, `$DirGroup`, , , Sets the default dirGroup to be used for an action if no explicit one is specified.
`DirGroupNum`, action, omfile, user process ID, , no, , , , Sets the default dirGroupNum to be used for an action if no explicit one is specified.
`DirGroupNum`, module, omfile, user process ID, , no, , , , Sets the default dirGroupNum to be used for an action if no explicit one is specified.
`dirOwner`, action, omfile, file mode, , no, `$DirOwner`, , , Set the file owner for directories newly created. 
`dirOwner`, module, omfile, file mode, , no, `$DirOwner`, , , Sets the default dirOwner to be used for an action if no explicit one is specified.
`DirOwnerNum`, action, omfile, integer, , no, `$DirOwnerNum`, 7.5.8, , Set the file owner for directories newly created. 
`DirOwnerNum`, module, omfile, integer, , no, , , , Sets the default dirOwnerNum to be used for an action if no explicit one is specified.
`DisableLFDelimiter`, input, imhttp, binary, `off`, no, , , , By default LF is used to delimit msg frames, for data is sent in batches. Set this to ‘`on`’ if this behavior is not needed.
`DisableLFDelimiter`, input, imtcp, binary, `<module parameter>`, no, , 8.2106.0, , This permits to override the equally-named module parameter on the `input()` level. For further details, see the module parameter. 
`DisableLFDelimiter`, module, imtcp, binary, `off`, no, , , , Industry-standard plain text tcp syslog uses the LF to delimit syslog frames. However, some users brought up the case that it may be useful to define a different delimiter and totally disable LF as a delimiter (the use case named were multi-line messages). This mode is non-standard and will probably come with a lot of problems. 
`DisableSASL`, action, omamqp1, integer, `0`, no, , 8.17.0, , Setting this to a non-zero value will disable SASL negotiation. Only necessary if the message bus does not offer SASL support.
`DiscardTruncatedMsg`, input, imtcp, binary, `<module parameter>`, no, , 8.2106.0, , This permits to override the equally-named module parameter on the `input()` level. For further details, see the module parameter.
`DiscardTruncatedMsg`, module, imptcp, binary, `off`, no, , , , When a message is split because it is to long the second part is normally processed as the next message. This can cause Problems. When this parameter is turned on the part of the message after the truncation will be discarded.
`DiscardTruncatedMsg`, module, imtcp, binary, `off`, no, , , , When a message is split because it is to long the second part is normally processed as the next message. This can cause Problems. When this parameter is turned on the part of the message after the truncation will be discarded.
`discardTruncateMsg`, input, imfile, binary, `off`, no, , , ,  When messages are too long they are truncated and the following part is processed as a new message. When this parameter is turned on the truncated part is not processed but discarded.
`DockerApiUnixSockAddr`, module, imdocker, string, `/var/run/docker.sock`, no, , 8.41.0, , Specifies the Docker unix socket address to use.
`documentroot`, module, imhttp, string, `.`, no, , , , Configures `document_root` in the civetweb library. This option may also be configured using liboptions, however this option will take precedence.
`Driver`, action, omlibdbi
`DriverDirectory`, module, omlibdbi
`dstmetadatapath`, module, mmkubernetes, word, `$!`, no, , , , This is the where the kubernetes and docker properties will be written. By default, the module will add `$!kubernetes` and `$!docker`.
`dynafile`, action, omfile, string, , no, , , , For each message, the file name is generated based on the given template. Then, this file is opened. As with the file property, data is appended if the file already exists. If the file does not exist, a new file is created.
`dynaFileCacheSize`, action, omfile, integer, `10`, no, `$DynaFileCacheSize`, , , This parameter specifies the maximum size of the cache for dynamically-generated file names (dynafile= parmeter). This setting specifies how many open file handles should be cached. 
`dynafile.donotsuspend`, module, omfile, binary, `on`, no, , , , This permits SUSPENDing dynafile actions. Traditionally, SUSPEND mode was never entered for dynafiles as it would have blocked overall processing flow. Default is not to suspend (and thus block).
`DynaKey`, action, omhiredis
`DynaKey`, action, omkafka
`DynaTopic`, action, omkafka
`DynaTopic.cachesize`, action, omkafka
`dynbulkid`, action, omelasticsearch, binary, `off`, no, , , , If this parameter is set to "`on`", then the bulkid parameter `omelasticsearch-bulkid` specifies a template to use to generate the unique id value to assign to the record.
`dynParent`, action, omelasticsearch, binary, `off`, no, , , , Using the same parent for all the logs sent in the same action is quite unlikely. So you'd probably want to turn this "on" and specify a rsyslog template that will provide meaningful parent IDs for your logs.
`dynPipelineName`, action, omelasticsearch, binary, `off`, no, , , , Like dynSearchIndex, it allows you to specify a rsyslog template for pipelineName, instead of a static string.
`dynrestpath`, action, omhttp
`dynSearchIndex`, action, omelasticsearch, binary, `off`, no, , , , Whether the string provided for searchIndex should be taken as a rsyslog template. Defaults to "`off`", which means the index name will be taken literally. 
`dynSearchType`, action, omelasticsearch, binary, `off`, no, , , , Like dynSearchIndex, it allows you to specify a rsyslog template for searchType, instead of a static string.
`embeddedipv4.anonmode`, action, mmanon, word, `zero`, no, , 7.3.7, , This defines the mode, in which IPv6 addresses will be anonymized. There exist the `random`, `random-consistent`, and `zero` option modes.
`embeddedipv4.bits`, action, mmanon, positive integer, `96`, no, , 7.3.7, , This sets the number of bits that should be anonymized (bits are from the right, so lower bits are anonymized first). This setting permits to save network information while still anonymizing user-specific data.
`embeddedipv4.enable`, action, mmanon, binary, `on`, no, , 7.3.7, , Allows to enable or disable the anonymization of IPv6 addresses with embedded IPv4.
`endmsg.regex`, input, imfile, string, , no, , 8.38.0, , This permits the processing of multi-line messages. When set, a message is terminated when `endmsg.regex` matches the line that identifies the end of a message.
`Endpoint`, input, imhttp, string, , yes, , , , Sets a request path for an http input. Path should always start with a '`/`'.
`EnsureLFEnding`, action, omstdout
`EnterpriseOID`, action, omsnmp
`errorFile`, action, omclickhouse, word, , no, , , , If specified, records failed in bulk mode are written to this file, including their error cause. Rsyslog itself does not process the file any more, but the idea behind that mechanism is that the user can create a script to periodically inspect the error file and react appropriately. As the complete request is included, it is possible to simply resubmit messages from that script.
`errorFile`, action, omelasticsearch, word, , no, , , , If specified, records failed in bulk mode are written to this file, including their error cause. Rsyslog itself does not process the file any more, but the idea behind that mechanism is that the user can create a script to periodically inspect the error file and react appropriately.
`errorfile`, action, omhttp
`errorFile`, action, omkafka
`escapeLF`, input, imdocker, binary, `on`, no, , 8.41.0, , This is only meaningful if multi-line messages are to be processed. LF characters embedded into syslog messages cause a lot of trouble, as most tools and even the legacy syslog TCP protocol do not expect these.
`escapeLF`, input, imfile, binary, `1`, no, , 8.2001.0, , This is only meaningful if multi-line messages are to be processed. LF characters embedded into syslog messages cause a lot of trouble, as most tools and even the legacy syslog TCP protocol do not expect these. If set to "`on`", this option avoid this trouble by properly escaping LF characters to the 4-byte sequence "`#012`".
`escapeLF.replacement`, input, imfile, string, depending on use, no, , 8.2001.0, , This parameter works in conjunction with `escapeLF`. It is only honored if `escapeLF="on"`.  It permits to replace the default escape sequence by a different character sequence. 
`esVersion.major`, action, omelasticsearch, integer, `0`, no, , 8.2402.0, , ElasticSearch is notoriously bad at maintaining backwards compatibility. For this reason, the setting can be used to configure the server's major version number (e.g. 7, 8, ...). As far as we know breaking changes only happen with major version changes. As of now, only value 8 triggers API changes. All other values select pre-version-8 API usage.
`eventproperties`, action, omazureeventhubs, array, , no, , 8.2301.0, , The eventproperties configuration property is an array property used to add key-value pairs as additional properties to the encoded AMQP message object, providing additional information about the log event. These properties can be used for filtering, routing, and grouping log events in Azure Event Hubs.
`exchange`, action, omrabbitmq
`expectedBootCompleteSeconds`, module, imkmsg, positive integer, 90 , no, , 8.2312.0, , This parameter works in conjunction with readMode and specifies how many seconds after startup the system should be considered to be "just booted", which means in readMode "full-boot" imkmsg reads and forwards to rsyslog processing all existing messages.
`Expiration`, action, omhiredis
`expiration`, action, omrabbitmq
`Facility`, action, imbatchreport, string, `local0`, no, , , , The syslog facility to be assigned to messages read from this file. Can be specified in textual form (e.g. `local0`, `local1`, ...) or as numbers (e.g. `16` for `local0`). Textual form is suggested.
Facility, action, improg, string, facility|number, no, , , , The syslog facility to be assigned to messages read from this file. Can be specified in textual form (e.g. `local0`, `local1`, ...) or as numbers (e.g. `16` for `local0`). Textual form is suggested.
`Facility`, action, imtuxedoulog, string, [facility|number], no, , , , The syslog facility to be assigned to messages read from this file. Can be specified in textual form (e.g. `local0`, `local1`, ...) or as numbers (e.g. `16` for `local0`). Textual form is suggested.
`Facility`, input, imfile, `local0`, no, , 8.0, , The syslog facility to be assigned to messages read from this file. Can be specified in textual form (e.g. `local0`, `local1`, ...) or as numbers (e.g. `16` for `local0`). Textual form is suggested. Default  is local0.
`Facility`, module, impstats, integer, `5`, no, , , , The numerical syslog facility code to be used for generated messages. Default is `5` (`syslog`). This is useful for filtering messages.
`failedMsgFile`, action, omkafka
`FailOnChOwnFailure`, input, imptcp, binary, on, `no`, , , , Rsyslog will not start if this is on and changing the file owner, group, or access permissions fails. Disable this to ignore these errors.
`failOnChOwnFailure`, input, omfile, binary, on, `no`, `$FailOnChOwnFailure`, , , This option modifies behaviour of file creation. If different owners or groups are specified for new files or directories and rsyslogd fails to set these new owners or groups, it will log an error and NOT write to the file in question if that option is set to "on". If it is set to "off", the error will be ignored and processing continues. Keep in mind, that the files in this case may be (in)accessible by people who should not have permission. The default is "on".
`fields`, input, imhiredis, array, `[]`, no, , , , When using `imhiredis_stream_mode`, the module won't get a simple entry but will instead get hashes, with field/value pairs. By default, the module will insert every value into their respective field in the "`$!`" object, but this parameter can change this behaviour, for each entry the value will be a string where:
`fields`, input, mmdarwin, array, , no, , 7.0, , Array containing values to be sent to Darwin as parameters.
`fields`, input, mmdblookup, array, , yes, , 8.24, , Fields that will be appended to processed message. The fields will always be appended in the container used by mmdblookup (which may be overridden by the `container` parameter on module load).
`File`, action, omfile, string, , no, , , , This creates a static file output, always writing into the same file. If the file already exists, new data is appended to it. Existing data is not truncated. If the file does not already exist, it is created. 
`File`, action, omhttpfs
`FileCreateMode, action, omfile, file mode, , no, `$FileCreateMode`, , , The FileCreateMode directive allows to specify the creation mode with which rsyslogd creates new files. If not specified, the value 0644 is used (which retains backward-compatibility with earlier releases). The value given must always be a 4-digit octal number, with the initial digit being zero. Please note that the actual permission depend on rsyslogd's process umask. If in doubt, use `$umask 0000` right at the beginning of the configuration file to remove any restrictions.
`fileCreateMode`, action, omprog
`FileCreateMode`, module, imjournal
`FileCreateMode, module, omfile, file mode, `O0644`, no, , , , Sets the default fileCreateMode to be used for an action if no explicit one is specified.
`FileGroup`, action, omfile, GID, `<system default>`, no, `$FileGroup`, , , Set the group for files newly created. Please note that this setting does not affect the group of files already existing. The parameter is a group name, for which the groupid is obtained by rsyslogd during startup processing. Interim changes to the user mapping are not detected.
`FileGroup`, module, omfile, GID, `<user process primary group>`, no, `$FileGroup`, , , Sets the default fileGroup to be used for an action if no explicit one is specified.
`FileGroupNum`, module, omfile, integer, `<system default>`, no, `$FileGroupNum`, 7.5.8, , Set the group for files newly created. Please note that this setting does not affect the group of files already existing. The parameter is a numerical ID, which is used regardless of whether the group actually exists. This can be useful if the group mapping is not available to rsyslog during startup.
`FileGroupNum`, module, omfile, integer, `<user process primary group>`, no, , , , Sets the default fileGroupNum to be used for an action if no explicit one is specified.
`File`, input, imfile, string, , yes, `$InputFileName`, 8.0, , The file being monitored. So far, this must be an absolute name (no macros or templates). Note that wildcards are supported at the file name level (see WildCards below for more details).
`file`, input, impcap, word, , no, , , , This parameter specifies a pcap file to read. The file must respect the pcap file format specification. If `file` is not specified, `interface` must be in order for the module to run.
`filenamebase`, module, mmkubernetes, word, `/etc/rsyslog.d/k8s_filename.rulebase`, no, , , , When processing json-file logs, this is the rulebase used to match the filename and extract metadata. For the actual rules, see filenamerules.
`filenamerules`, module, mmkubernetes, word, `*`, no, , , , This directive is not supported with liblognorm 2.0.2 and earlier.  When processing json-file logs, these are the lognorm rules to use to match the filename and extract metadata. The default value is: `rule=:/var/log/containers/%pod_name:char-to:_%_%namespace_name:char-to:_%_%container_name_and_id:char-to:.%.log`
`fileOwner`, action, omfile, UID, `<user pprocess ID>`, no, , , , Sets the default fileOwner to be used for an action if no explicit one is specified.
`FileOwner`, input, imptcp, UID, `<system default>`, no, , , , Set the file owner for the domain socket. The parameter is a user name, for which the userid is obtained by rsyslogd during startup processing. Interim changes to the user mapping are not detected.
`fileOwner`, module, omfile, UID, `<user pprocess ID>`, no, , , , Sets the default fileOwner to be used for an action if no explicit one is specified.
`fileOwnerNum`, action, omfile, integer, `<user process ID>`, no, , 7.5.8, , Sets the default fileOwnerNum to be used for an action if no explicit one is specified.
`FileOwnerNum`, input, imfile, integer, `<process user>`, no, , , , Sets the default fileOwnerNum to be used for an action if no explicit one is specified.
`FileOwnerNum`, input, imptcp, integer, `<system default>`, no, , , , Set the file owner for the domain socket. The parameter is a numerical ID, which which is used regardless of whether the user actually exists. This can be useful if the user mapping is not available to rsyslog during startup.
`fileOwnerNum`, module, omfile, integer, `<user process ID>`, no, , , , Sets the default fileOwnerNum to be used for an action if no explicit one is specified.
`file`, ruleset, builtin
`FilterCode`, input, mmdarwin, word, `0x00000000`, no, , 7.0.0, ,  Each Darwin module has a unique filter code. For example, the code of the hostlookup filter is `0x66726570`.  This code was mandatory but has now become obsolete. you can leave it as it is.
`filter`, input, impcap, string, , no, , , , Set a filter for the capture. Filter semantics are defined on pcap manpages.
`flowControl`, input, imhttp, binary, `on`, no, , , , Flow control is used to throttle the sender if the receiver queue is near-full preserving some space for input that can not be throttled.
`flowControl`, input, imptcp, binary, `on`, no, , , , Flow control is used to throttle the sender if the receiver queue is near-full preserving some space for input that can not be throttled.
`flowControl`, input, imrelp, string, `light`, no, , 8.1911.0, , This parameter permits the fine-tuning of the flowControl parameter. Possible values are `no`, `light`, and `full`. With `light` being the default and previously only value.
`FlowControl`, input, imtcp, binary, `<module parameter>`, no, , 8.2106.0, , This permits to override the equally-named module parameter on the `input()` level. For further details, see the module parameter.
`FlowControl`, input, imuxsock, binary, `off`, no, `$InputUnixListenSocketFlowControl`, , , Specifies if flow control should be applied to the input being defined.
`FlowControl`, module, imtcp, binary, `on`, no, `$InputTCPFlowControl`, , , This setting specifies whether some message flow control shall be exercised on the related TCP input. If set to on, messages are handled as "light delayable", which means the sender is throttled a bit when the queue becomes near-full. This is done in order to preserve some queue space for inputs that can not throttle (like UDP), but it may have some undesired effect in some configurations. Still, we consider this as a useful setting and thus it is the default. To turn the handling off, simply configure that explicitly.
`flushInterval`, action, omfile, integer, `1`, no, `$OMFileFlushInterval`, , , Defines, in seconds, the interval after which unwritten data is flushed.
`flushOnTXEnd`, action, omfile, binary, `on`, no, `$OMFileFlushOnTXEnd`, , , Omfile has the capability to write output using a buffered writer. Disk writes are only done when the buffer is full. So if an error happens during that write, data is potentially lost. 
`ForceLocalHostname`, action, mmtaghostname, binary, `off`, no, , , , This attribute force to set the `HOSTNAME` of the message to the rsyslog value "`localHostName`". This allow to set a valid value to message received received from local application through imudp or imtcp.
`forceSingleInstance`, action, mmexternal, binary, `off`, no, , 8.3.0, , This is an expert parameter, just like the equivalent omprog parameter. See the message modification plugin's documentation if it is needed.
`forceSingleInstance`, action, omprog
`Format`, module, impstats, word, `legacy`, no, , 8.16.0, , Specifies the format of emitted stats messages. The default of `legacy` is compatible with pre v6-rsyslog. The other options provide support for structured formats (note the "cee" is actually "project lumberjack" logging).
`framing.delimiter.regex`, input, imptcp, string, , no, , , , Experimental parameter. It is similar to `MultiLine`, but provides greater control of when a log message ends. You can specify a regular expression that characterizes the header to expect at the start of the next message. As such, it indicates the end of the current message. For example, one can use this setting to use a RFC3164 header as frame delimiter: `framing.delimiter.regex="^<[0-9]{1,3}>(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)"`
`Framingfix.cisco.asa`, input, imptcp, `binary`, off, no, , , , Cisco very occasionally sends a space after a line feed, which thrashes framing if not taken special care of. When this parameter is set to `on`, we permit space in front of the next frame and ignore it.
`freshStartTail`, input, imfile, binary, `off`, no, , , , This is used to tell rsyslog to seek to the end/tail of input files (discard old logs) at its first start(freshStart) and process only new log messages.
`FSync`, module, imjournal, binary, `off`, no, , 8.1908, , When there is a hard crash, power loss or similar abrupt end of rsyslog process, there is a risk of state file not being written to persistent storage or possibly being corrupted. 
`GetContainerLogOptions`, module, imdocker, string, `timestamp=0&follow=1&stdout=1&stderr=1&tail=1`, no, , 8.41.0, , Specifies the http query component of the a 'Get container logs' HTTP API request. See Docker API for more information about available options. Note: It is not necessary to prepend the string with '`?`'.
`gnutlsPriorityString`, input, imtcp, string, `<module parameter>`, no, , 8.2106.0, , This permits to override the equally-named module parameter on the `input()` level. For further details, see the module parameter.
`gnutlsPriorityString`, module, imtcp, string, , no, , 8.29.0, , The "gnutls priority string" parameter in rsyslog offers enhanced customization for secure communications, allowing detailed configuration of TLS driver properties. 
`hashfunction`, action, mmrfc5424addhmac, function, , no, , 7.5.6, , An openssl hash function name for the function to be used. This is passed on to openssl, so see the openssl list of supported function names.
`healthCheckTimeout`, action, omclickhouse, integer, `3500`, no, , , , This parameter sets the timeout for checking the availability of ClickHouse. Value is given in milliseconds.
`HealthCheckTimeout`, action, omelasticsearch, integer, `3500`, no, , 8.2402.0, , Specifies the number of milliseconds to wait for a successful health check on a server. Before trying to submit events to Elasticsearch, rsyslog will execute an `HTTP HEAD` to `/_cat/health` and expect an `HTTP OK` within this timeframe. Defaults to `3500`.
`healthchecktimeout`, action, omhttp
`heartbeat_interval`, action, omrabbitmq
`Host`, action, omamqp1, word, `5672`, yes, , 8.17.0, , The address of the message bus in `host[:port]` format. The port defaults to `5672` if absent. Examples: `localhost`, `127.0.0.1:9999`, `bus.someplace.org`
`Host`, action, omhttpfs
`host`, action, omrabbitmq
`HostName`, input, imuxsock, string, `NULL`, no, `$InputUnixListenSocketHostName`, , , Allows overriding the hostname that shall be used inside messages taken from the input that is being defined.
`httpcontenttype`, action, omhttp
`httpheaderkey`, action, omhttp
`httpheaders`, action, omhttp
`httpheadervalue`, action, omhttp
`https`, action, omhttpfs
`hup.signal`, action, omprog
`id`, action, timezone
`idleTimeout`, action, omamqp1, integer, `0`, no, , 8.17.0, , The idle timeout in seconds. This enables connection heartbeats and is used to detect a failed connection to the message bus. Set to zero to disable. 
`IgnoreNonValidStatefile`, module, imjournal, binary, `on`, no, , 7.11.3, , When a corrupted statefile is read imjournal ignores the statefile and continues with logging from the beginning of the journal (from its end if IgnorePreviousMessages is on). 
`ignoreOlderThan`, input, imfile
`IgnoreOwnMessages`, input, imuxsock, binary, `on`, no, , 7.3.7, , Ignore messages that originated from the same instance of rsyslogd. There usually is no reason to receive messages from ourselves. This setting is vital when writing messages to the systemd journal.
`IgnorePreviousMessages`, module, imjournal, binary, `off`, no, `$imjournalIgnorePreviousMessages`, 7.11.3, , This option specifies whether imjournal should ignore messages currently in journal and read only new messages. This option is only used when there is no StateFile to avoid message loss.
`IgnoreTimestamp`, input, imuxsock, binary, `on`, no, `$InputUnixListenSocketIgnoringMsgTimestamp`, , , Ignore timestamps included in messages received from the input being defined.
`indexTimeout`, action, omelasticsearch, integer, `0`, no, , 8.2204.0, , Specifies the number of milliseconds to wait for a successful log indexing request on a server. By default there is no timeout.
`init_openssl`, action, omrabbitmq
`Input3195ListenPort`, input, im3195, integer, `601`, no, `$Input3195ListenPort`, , , The port on which imklog listens for RFC 3195 messages. The default port is `601` (the IANA-assigned port)
`InputGSSListenPortFileName`, input, imgssapi, word, , no, `$InputGSSListenPortFileName`, 8.38.0, , With this parameter you can specify the name for a file. In this file the port, imtcp is connected to, will be written. This parameter was introduced because the testbench works with dynamic ports.
`InputGSSServerKeepAlive`, input, imgssapi, binary, `0`, no, `$InputGSSServerKeepAlive`, 8.5.0, , Enables or disable keep-alive handling.
`InputGSSServerMaxSessions`, input, imgssapi, integer, `200`, no, `$InputGSSServerMaxSessions`, , , Sets the maximum number of sessions supported.
`InputGSSServerPermitPlainTCP`, input, imgssapi, binary, `0`, no, `$InputGSSServerPermitPlainTCP`, , , Permits the server to receive plain tcp syslog (without GSS) on the same port.
`InputGSSServerRun`, input, imgssapi, word, , no, `$InputGSSServerRun`, , , Starts a GSSAPI server on selected port - note that this runs independently from the TCP server.
`InputGSSServerServiceName`, input, imgssapi, word, , no, `$InputGSSServerServiceName`, , , The service name to use for the GSS server.
`interface.input`, action, mmexternal, string, `msg`, no, , 8.3.0, , This can either be "`msg`", "`rawmsg`" or "`fulljson`". In case of "`fulljson`", the message object is provided as a json object. Otherwise, the respective property is provided. 
`interface`, input, impcap, word, , no, , , , This parameter specifies the network interface to listen to. If `interface` is not specified, `file` must be in order for the module to run.
`InternalMsgFacility`, module, imklog, facility, `*`, no, `$KLogInternalMsgFacility`, , , The facility which messages internally generated by `imklog` will have. `imklog` generates some messages of itself (e.g. on problems, startup and shutdown) and these do not stem from the kernel.
`interval`, module, immark, integer, `1200`, no, `$MarkMessagePeriod`, , , Specifies the mark message injection interval in seconds.
`Interval`, module, impstats, integer, `300`, no, , , , Sets the interval, in seconds at which messages are generated. Please note that the actual interval may be a bit longer. 
`ioBufferSize`, action, omfile, size, `4KiB`, no, `$OMFileIOBufferSize`, , , Size of the buffer used to writing output data. The larger the buffer, the potentially better performance is. The default of 4k is quite conservative, it is useful to go up to 64k, and 128k if you used gzip compression (then, even higher sizes may make sense)
`IpFreeBind`, input, imudp, integer, `2`, no, , 8.18.0, , Manages the `IP_FREEBIND` option on the UDP socket, which allows binding it to an IP address that is nonlocal or not (yet) associated to any network interface.  The parameter accepts the following values: 0 - does not enable the `IP_FREEBIND` option on the UDP socket. If the bind() call fails because of `EADDRNOTAVAIL` error, socket initialization fails.; 1 - silently enables the `IP_FREEBIND` socket option if it is required to successfully bind the socket to a nonlocal address.; 2 - enables the `IP_FREEBIND` socket option and warns when it is used to successfully bind the socket to a nonlocal address.
`ipv4.bits`, action, mmanon, positive integer, `16`, no, , 7.3.7, , This sets the number of bits that should be anonymized (bits are from the right, so lower bits are anonymized first). This setting permits to save network information while still anonymizing user-specific data. The more bits you discard, the better the anonymization obviously is.
`ipv4.enable`, action, mmanon, binary, `on`, no, , 7.3.7, , Allows to enable or disable the anonymization of IPv4 addresses.
`ipv4.mode`, action, mmanon, word, `zero`, no, , 7.3.7, , There exist the "`simple`", "`random`", "`random-consistent`", and "`zero`" modes. In simple mode, only octets as whole can be anonymized and the length of the message is never changed.
`ipv4.replaceChar`, action, mmanon, char, `x`, no, , 7.3.7, , In simple mode, this sets the character that the to-be-anonymized part of the IP address is to be overwritten with. In any other mode the parameter is ignored if set.
`ipv6.anonmode`, action, mmanon, word, `zero`, no, , 7.3.7, , This defines the mode, in which IPv6 addresses will be anonymized. There exist the "random", "random-consistent", and "zero" modes.
`ipv6.bits`, action, mmanon, positive integer, `96`, no, , 7.3.7, , This sets the number of bits that should be anonymized (bits are from the right, so lower bits are anonymized first). This setting permits to save network information while still anonymizing user-specific data. The more bits you discard, the better the anonymization obviously is.
`ipv6.enable`, action, mmanon, binary, `on`, no, , 7.3.7, , Allows to enable or disable the anonymization of IPv6 addresses.
`isDynFile`, action, omhttpfs
`jsonRoot`, action, mmfields, string, `!`, no, , 7.5.1, , This parameters specifies into which json path the extracted fields shall be written. The default is to use the json root object itself. 
`jsonRoot`, action, mmstructdata, string, `!`, no, , 7.5.4, , Specifies into which json container the data shall be parsed to.
`KeepAlive`, input, imrelp, binary, `off`, no, `$InputRELPServerKeepAlive`, , , Enable or disable keep-alive packets at the TCP socket layer. By defauly keep-alives are disabled.
`KeepAlive`, input, imtcp, binary, `<module parameter>`, no, , 8.2106.0, , This permits to override the equally-named module parameter on the `input()` level. For further details, see the module parameter.
`KeepAlive.Interval`, input, imptcp, integer, `0`, no, `$InputPTCPServerKeepAlive_intvl`, , , The interval between subsequential keepalive probes, regardless of what the connection has exchanged in the meantime. The default, `0`, means that the operating system defaults are used. This has only effect if keep-alive is enabled. The functionality may not be available on all platforms.
`KeepAlive.Interval`, input, imrelp, integer, `0`, no, , 8.2008.0, , The interval between subsequent keep-alive probes, regardless of what the connection has been exchanged in the meantime. The default, `0`, means that the operating system defaults are used. This only has an effect if keep-alive is enabled. The functionality may not be available on all platforms.
`KeepAlive.Interval`, input, imtcp, integer, `<module parameter>`, no, , 8.2106.0, , This permits to override the equally-named module parameter on the `input()` level. For further details, see the module parameter.
`KeepAlive.Interval`, module, imtcp, integer, `0`, no, , 8.2106.0, , The interval for keep alive packets.
`KeepAlive`, module, imptcp, binary, `off`, no, `$InputPTCPServerKeepAlive`, , , Enable of disable keep-alive packets at the tcp socket layer. The default is to disable them.
`KeepAlive`, module, imtcp, binary, `off`, no, `$InputTCPServerKeepAlive`, , , Enable or disable keep-alive packets at the TCP socket layer. By defauly keep-alives are disabled.
`KeepAlive.Probes`, input, imptcp, integer, `0`, no, , , , The number of unacknowledged probes to send before considering the connection dead and notifying the application layer. The default, `0`, means that the operating system defaults are used. This has only effect if keep-alive is enabled. The functionality may not be available on all platforms.
`KeepAlive.Probes`, input, imrelp, integer, `0`, no, , , , The number of keep-alive probes to send before considering the connection dead and notifying the application layer. The default, `0`, means that the operating system defaults are used. This only has an effect if keep-alives are enabled. The functionality may not be available on all platforms.
`KeepAlive.Probes`, module, imtcp, integer, `0`, no, `$InputTCPServerKeepAlive`, , , The number of keep-alive probes to send before considering the connection dead and notifying the application layer. The default, `0`, means that the operating system defaults are used. This only has an effect if keep-alives are enabled. The functionality may not be available on all platforms.
`KeepAlive.Time`, input, imptcp, integer, `<module parameter>`, no, , 8.2106.0, , This permits to override the equally-named module parameter on the `input()` level. For further details, see the module parameter.
`KeepAlive.Time`, input, imrelp, integer, `0`, no, , 8.2008.0, , The interval between the last data packet sent (simple ACKs are not considered data) and the first keepalive probe; after the connection is marked with keep-alive, this counter is not used any further. The default, `0`, means that the operating system defaults are used. This only has an effect if keep-alive is enabled. The functionality may not be available on all platforms.
KeepAlive.Time, input, imtcp, integer, `<module parameter>`, no, , 8.2106.0, , This permits to override the equally-named module parameter on the `input()` level. For further details, see the module parameter.
`KeepAlive.Time`, module, imtcp, integer, `0`, no, `$InputTCPServerKeepAlive_time`, , , The interval between the last data packet sent (simple ACKs are not considered data) and the first keepalive probe; after the connection is marked to need keepalive, this counter is not used any further. The default, `0`, means that the operating system defaults are used. This has only effect if keep-alive is enabled. The functionality may not be available on all platforms.
`KeepFailedMessages`, action, omkafka
`KeepKernelTimestamp`, module, imklog, binary, `off`, no, `$klogKeepKernelTimestamp`, , , If enabled, this option causes to keep the [timestamp] provided by the kernel at the begin of in each message rather than to remove it, when it could be parsed and converted into local time for use as regular message time.
`key`, action, mmcount, 7.5.0, ,
`key`, action, mmrfc5424addhmac, string, , no, , 7.5.6, , The "`key`" to be used to generate the hmac.
`Key`, action, omhiredis
`Key`, action, omkafka
`key`, input, imhiredis, word, , no, , , , Defines either the name of the list to use (for `imhiredis_queue_mode`) or the channel to listen to (for `imhiredis_channel_mode`).
`key`, input, mmdarwin, word, , yes, , 7.0.0, , The key name to use to store the returned data.
`key`, input, mmdblookup, word, , yes, , 8.24, , Name of field containing IP address.
`killUnresponsive`, action, improg, binary, `on`, no, , , , Specifies whether a KILL signal must be sent to the external program in case it does not terminate within the timeout indicated by closeTimeout (when either the worker thread has been unscheduled, a restart of the program is being forced, or rsyslog is about to shutdown).
`killUnresponsive`, action, omprog
`KubernetesURL`, module, mmkubernetes, word, `https://kuberneters.default.svc.cluster.local:443`, no, , , , The URL of the Kubernetes API server. Example: `https://localhost:8443`.
`liboptions`, module, imhttp, string, , no, , , , Configures civetweb library "Options".
`ListContainersOptions`, module, imdocker, string, , no, , 8.41.0, , Specifies the http query component of the a 'List Containers' HTTP API request. See Docker API for more information about available options. Note: It is not necessary to prepend the string with '`?`'.
`ListenPortFileName`, input, imptcp, string, , no, , 8.38.0, , With this parameter you can specify the name for a file. In this file the port, imptcp is connected to, will be written. This parameter was introduced because the testbench works with dynamic ports.
`ListenPortFileName`, input, iptcp, string, , no, , 8.38, , This parameter specifies a file name into which the port number this input listens on is written. It is primarily intended for cases when port is set to `0` to let the OS automatically assign a free port number.
`log.file`, module, impstats, word, , no, , , , If specified, statistics data is written to the specified file. For robustness, this should be a local file. The file format cannot be customized, it consists of a date header, followed by a colon, followed by the actual statistics record, all on one line. 
`LogPath`, module, imklog, word, `*`, no, `$klogpath`, , , Defines the path to the log file that is used. If this parameter is not set a default will be used. On Linux "`/proc/kmsg`" and else "`/dev/klog`".
`log.syslog`, module, impstats, binary, `on`, no, , , , This is a boolean setting specifying if data should be sent to the usual syslog stream. This is useful if custom formatting or more elaborate processing is desired.
`MailFrom`, action, ommail
`MailTo`, action, ommail
`Main`, input, imjournal, word, `journal`, no, , 8.2312.0, , When this option is turned on within the input module, imjournal will run the target ruleset in the main thread and will be stop taking input if the output module is not accepting data. 
`maxbytes`, action, omelasticsearch, word, `100m`, no, , 8.23.0, , When shipping logs with bulkmode on, maxbytes specifies the maximum size of the request body sent to Elasticsearch. Logs are batched until either the buffer reaches maxbytes or the dequeue batch size is reached. In order to ensure Elasticsearch does not reject requests due to content length, verify this value is set according to the `http.max_content_length` setting in Elasticsearch. Defaults to `100m`.
`MaxBytesPerMinute`, input, imfile, integer, `0`, no, , , , Instructs rsyslog to enqueue a maximum number of bytes as messages per minute. Once `MaxBytesPerMinute` is reached, subsequent messages are discarded.
`MaxDataSize`, input, imrelp, `<size_number>`, no, , , , Sets the max message size (in bytes) that can be received. Messages that are too long are handled as specified in parameter oversizeMode. Note that maxDataSize cannot be smaller than the global parameter maxMessageSize.
`MaxFrameSize`, input, imptcp, integer, `200000`, no, , , , When in octet counted mode, the frame size is given at the beginning of the message. With this parameter the max size this frame can have is specified and when the frame gets to large the mode is switched to octet stuffing. The max value this parameter can have was specified because otherwise the integer could become negative and this would result in a Segmentation Fault. (Max Value: `200000000`)
`MaxFrameSize`, module, imtcp, integer, `200000`, no, , , , When in octet counted mode, the frame size is given at the beginning of the message. With this parameter the max size this frame can have is specified and when the frame gets to large the mode is switched to octet stuffing. The max value this parameter can have was specified because otherwise the integer could become negative and this would result in a Segmentation Fault. (Max Value = `200000000`)
`MaxLinesAtOnce`, input, imfile, integer, `0`, no, `$InputFileMaxLinesAtOnce`, , , This is a legacy setting that only is supported in polling mode. In inotify mode, it is fixed at 0 and all attempts to configure a different value will be ignored, but will generate an error message.
`MaxLinesAtOnce`, input, imtuxedoulog, integer, `0`, no, , , , If set to `0`, the file will be fully processed. If it is set to any other value, a maximum of [number] lines is processed in sequence. The default is `10240`.
`MaxLinesPerMinute`, input, imfile, integer, `0`, no, , , , Instructs rsyslog to enqueue up to the specified maximum number of lines as messages per minute. Lines above this value are discarded.
`MaxListeners`, input, imtcp, integer, `<module parameter>`, no, , 8.2106.0, , This permits to override the equally-named module parameter on the `input()` level. For further details, see the module parameter.
`MaxListeners`, module, imtcp, integer, `20`, no, `$InputTCPMaxListeners`, , , Sets the maximum number of listeners (server ports) supported. This must be set before the first `$InputTCPServerRun` directive.
`MaxRetries`, action, omamqp1, integer, `10`, no, , 8.17.0, , The number of times an undeliverable message is re-sent to the message bus before it is dropped. This is unrelated to rsyslog’s `action.resumeRetryCount`.
`MaxSessions`, input, imptcp, integer, `0`, no, , , , Maximum number of open sessions allowed. This is inherited to each `input()` config, however it is not a global maximum, rather just setting the default per input. A setting of zero or less than zero means no limit.
`MaxSessions`, input, imtcp, integer, `<module parameter>`, no, , 8.2106.0, , This permits to override the equally-named module parameter on the `input()` level. For further details, see the module parameter.
`MaxSessions`, module, imtcp, integer, `200`, no, `$InputTCPMaxSessions`, , , Sets the maximum number of sessions supported. This must be set before the first `$InputTCPServerRun` directive.
`MaxSubmitAtOnce`, input, imfile, integer, `1024`, no, , , , This is an expert option. It can be used to set the maximum input batch size that imfile can generate. The default is `1024`, which is suitable for a wide range of applications.
`MaxSubmitAtOnce`, input, imtuxedoulog, integer, `1024`, no, , , , This is an expert option. It can be used to set the maximum input batch size that the module can generate. The default is 1024, which is suitable for a wide range of applications.
`MessageOID`, action, omsnmp
`metadata_container`, module, impcap, word, `impcap`, no, , , , Defines the container to place all the parsed metadata of the network packet.
`mmdbfile`, input, mmdblookup, word, , yes, , 8.24, , Location of Maxmind DB file.
`mode`, action, mmsequence, word, , no, , 7.5.6, , "`random`" or "`instance`" or "`key`" specifies mode of the action. In "`random`" mode, the module generates uniformly distributed integer numbers in a range defined by "`from`" and "`to`".  In "`instance`" mode, which is default, the action produces a counter in range [`from`, `to`). This counter is specific to this action instance.  In "`key`" mode, the counter can be shared between multiple instances. This counter is identified by a name, which is defined with "`key`" parameter.
`mode`, action, mmutf8fix, string, , no, , 7.5.6, , This sets the basic detection mode. In utf-8 mode (the default), proper UTF-8 encoding is checked and bytes which are not proper UTF-8 sequences are acted on. If a proper multi-byte start sequence byte is detected but any of the following bytes is invalid, the whole sequence is replaced by the replacement method. 
`Mode`, action, omhiredis, word, `subscribe`, yes, , , , Defines the mode to use for the module.  Should be either `subscribe` (`imhiredis_channel_mode`), `queue` (`imhiredis_queue_mode`) or `stream` (`imhiredis_stream_mode`) (case-sensitive).
`mode`, input, imhiredis
`Mode`, module, imfile, word, `inotify`, no, , 8.1.5, , This specifies if imfile is shall run in inotify ("`inotify`") or polling ("`polling`") mode. 
`Mode`, module, imkmsg, word, `parseKernelTimestamp`, no, , 8.2312.0, , This parameter configures which timestamps will be used. It is an advanced setting and most users should probably keep the default mode ("startup").
`msgDiscardingError`, input, imfile, binary, `on`, no, , , , Upon truncation an error is given. When this parameter is turned off, no error will be shown upon truncation.
`MTU`, action, omudpspoof
`MultiLine`, input, imptcp, binary, `off`, no, , , , Experimental parameter which causes rsyslog to recognise a new message only if the line feed is followed by a "`<`" or if there are no more characters.
`MySQLConfig.File`, action, ommysql
`MySQLConfig.Section`, action, ommysql
`name`, action, builtin
`name`, action, imdtls, word, , no, , 8.2402.0, , Unique name to the input module instance. This is useful for identifying the source of messages when multiple input modules are used.
`Name.appendPort`, input, imudp, binary, `off`, no, , 7.3.9, , Appends the port the inputname property. Note that when no "name" is specified, the default of "`imudp`" is used and the port is appended to that default. So, for example, a listener port of `514` in that case will lead to an inputname of "`imudp514`". 
`Name`, `input`, `imhttp`, `string`, `imhttp`, `no`, , , , Sets a name for the inputname property. If no name is set "`imhttp`" is used by default. Setting a name is not strictly necessary, but can be useful to apply filtering based on which input the message was received from.
`Name`, input, imptcp, string, `imptcp`, no, `$InputPTCPServerInputName`, , , 
`Name`, input, imrelp, string, `imrelp`, no, , , , Sets a name for the inputname property. If no name is set "`imrelp`" is used by default. Setting a name is not strictly necessary, but can be useful to apply filtering based on which input the message was received from. Note that the name also shows up in impstats `<impstats>` logs.
`Name`, input, imtcp, string, `imtcp`, no, `$InputTCPServerInputName`, , , Sets a name for the inputname property. If no name is set "`imtcp`" is used by default. Setting a name is not strictly necessary, but can be useful to apply filtering based on which input the message was received from.
`Name`, input, imudp, word, `imudp`, no , 8.3.3, , Specifies the value of the inputname property. In older versions, this was always "imudp" for all listeners, which still is the default. Starting with 7.3.9 it can be set to different values for each listener. Note that when a single input statement defines multiple listener ports, the inputname will be the same for all of them. If you want to differentiate in that case, use "name.appendPort" to make them unique.
`name`, parser, builtin
`name`, ruleset, builtin
`needParse`, input, imfile
`no_buffer`, input, impcap, boolean, `off`, no, , , , Disable buffering during capture. By default, impcap asks the system to bufferize packets (see parameters `buffer_size`, `buffer_timeout` and `packet_count`), this parameter disables buffering completely. 
`NotifyOnConnectionClose`, input, imptcp, binary, `off`, no, `$InputPTCPServerNotifyOnConnectionClose`, , , Instructs imptcp to emit a message if a remote peer closes the connection.
`NotifyOnConnectionClose`, input, imtcp, binary, `<module parameter>`, no , , 8.2106.0, , This permits to override the equally-named module parameter on the `input()` level. For further details, see the module parameter.
`NotifyOnConnectionClose`, module, imtcp, binary, `off`, no , `$InputTCPServerNotifyOnConnectionClose`, , , Instructs imtcp to emit a message if the remote peer closes a connection.
`NotifyOnConnectionOpen`, input, imptcp, binary, `off`, no, , , , Instructs imptcp to emit a message if a remote peer opens a connection. Hostname of the remote peer is given in the message.
`NotifyOnConnectionOpen`, module, imtcp, binary, `off`, no, `$InputTCPServerNotifyOnConnectionOpen`, , , Instructs imtcp to emit a message if the remote peer opens a connection.
`offset`, action, timezone
`output`, action, mmexternal, string, , no, , 8.3.0, , This is a debug aid. If set, this is a filename where the plugins output is logged. Note that the output is also being processed as usual by rsyslog. Setting this parameter thus gives insight into the internal processing that happens between plugin and rsyslog core.
`output`, action, omprog
`oversizeMode`, input, imrelp, string, truncate, no, , 8.35.0, , This parameter specifies how messages that are too long will be handled. For this parameter the length of the parameter maxDataSize is used.
`packet_count`, input, impcap, number, `5`, no, , , , Set a maximum number of packets to process at a time. This parameter allows to limit batch calls to a maximum of X packets at a time.
`parent`, action, omelasticsearch, word, , no, , , , Specifying a string here will index your logs with that string the parent ID of those logs. Please note that you need to define the parent field in your mapping for that to work. By default, logs are indexed without a parent.
`ParseHostname`, action, imkafka, binary, `off`, no, , 8.38.0, , If this parameter is set to on, imkafka will parse the hostname in log if it exists. 
`ParseHostname`, input, imuxsock, binary, `off`, no, , 8.9.0, , Equivalent to the SysSock.ParseHostname module parameter, but applies to the input that is being defined.
`ParseKernelTimestamp`, module, imklog
`ParseTrusted`, input, imuxsock, binary, `off`, no, `$ParseTrusted`, , , Equivalent to the SysSock.ParseTrusted module parameter, but applies to the input that is being defined.
`Partitions.Auto`, action, omkafka
`Partitions.number`, action, omkafka
`Partitions.useFixed`, action, omkafka
`Pass`, action, ompgsql
`Password`, action, omamqp1, word, , no, , 8.17.0, , Used by SASL to authenticate with the message bus.
`password`, action, omrabbitmq
`password`, input, imhiredis, word, , no, , , , The password to use when connecting to a Redis node, if necessary.
`path`, action, mmnormalize, word, `$!`, no, , 6.1.3, , Specifies if the raw message should be used for normalization (`on`) or just the MSG part of the message (`off`).
`Path`, input, imptcp, string, , no, , , , A path on the filesystem for a unix domain socket. It is an error to specify both path and port.
`PermitNonKernelFacility`, module, imklog, binary, `off`, no, `$KLogPermitNonKernelFacility`, , , At least under BSD the kernel log may contain entries with non-kernel facilities. This setting controls how those are handled. The default is "`off`", in which case these messages are ignored. Switch it to on to submit non-kernel messages to rsyslog processing.
`PermittedPeer`, input, imtcp, array, `<module parameter>`, no, , 8.2112.0, , This permits to override the equally-named module parameter on the `input()` level. For further details, see the module parameter.
`PermittedPeer`, module, imtcp, array, , no, , , , 
`PermittedPeer`, module, imtcp, array, , no, `$InputTCPServerStreamDriverPermittedPeer`, , , Sets permitted peer IDs. Only these peers are able to connect to the listener. `<id-string>` semantics depend on the currently selected `AuthMode` and network stream driver `<../../concepts/netstrm_drvr>`. `PermittedPeer` may not be set in anonymous modes. `PermittedPeer` may be set either to a single peer or an array of peers either of type IP or name, depending on the tls certificate.  Single peer: `PermittedPeer="127.0.0.1"`; Array of peers: `PermittedPeer=["test1.example.net","10.1.2.3","test2.example.net","..."`]
`persistStateAfterSubmission`, input, imfile
`PersistStateInterval`, action, imtuxedoulog, integer, `0`, no, , , , Specifies how often the state file shall be written when processing the input file. The default value is `0`, which means a new state file is only written when the monitored files is being closed (end of rsyslogd execution). Any other value n means that the state file is written every time n file lines have been processed. 
`PersistStateInterval`, input, imfile, integer, `0`, no, `$InputFilePersistStateInterval`, 8.0, , Specifies how often the state file shall be written when processing the input file. The default value is `0`, which means a new state file is at least being written when the monitored files is being closed (end of rsyslogd execution). Any other value n means that the state file is written at least every time n file lines have been processed. 
`PersistStateInterval`, module, imjournal, integer, `10`, no, `$imjournalPersistStateInterval`, 7.3.11, , This is a global setting. It specifies how often should the journal state be persisted. The persists happens after each number-of-messages. This option is useful for rsyslog to start reading from the last journal message it read.
`Pipe`, action, ompipe
`pipelineName`, action, omelasticsearch, word, , no, , The ingest node pipeline name to be included in the request. This allows pre processing of events before indexing them. By default, events are not send to a pipeline.
`PollingInterval`, module, imdocker, integer, `60`, no, , 8.41.0, , Specifies the polling interval in seconds, imdocker will poll for new containers by calling the 'List containers' API from the Docker engine.
`PollingInterval`, module, imfile
`populate_properties`, action, omrabbitmq
`port`, action, imdtls, word, `4433`, yes, , 8.2402.0, , Specifies the UDP port to which the imdtls module will bind and listen for incoming connections. The default port number for DTLS is `4433`. 
`Port`, action, omclickhouse, integer, `8123`, no, , , , HTTP port to use to connect to ClickHouse.
` port`, action, omdtls, word, `4433`, yes, , 8.2402.0, , Defines the port number on the target host where log messages will be sent. The default port number for DTLS is `4433`.
`Port`, action, omhttpfs
`Port`, action, ommail
`Port`, action, ompgsql
`port`, action, omrabbitmq
`Port`, action, omrelp
`Port`, action, omsnmp
`Port`, action, omudpspoof
`port`, input, imhiredis, number, `6379`, no, , , , The Redis server's port to use when connecting via IP.
`Port`, input, imptcp, string, , no, , , , Select a port to listen on. It is an error to specify both path and port.
`Port`, input, imrelp, string, , yes, `$InputRELPServerRun`, , , Starts a RELP server on selected port
`Port`, input, imtcp, string, , yes, `$InputTCPServerRun`, , , Starts a TCP server on selected port. If port zero is selected, the OS automatically assigens a free port. Use listenPortFileName in this case to obtain the information of which port was assigned.
`Port`, input, imudp, array, `514`, yes, `$UDPServerRun`, , , Specifies the port the server shall listen to.. Either a single port can be specified or an array of ports. If multiple ports are specified, a listener will be automatically started for each port. Thus, no additional inputs need to be configured.  Single port: `Port="514"`; Array of ports: `Port=["514","515","10514","..."]`
`Ports`, module, imhttp, string, `8080`, no, , , , Configures "`listening_ports`" in the civetweb library. This option may also be configured using the liboptions (below) however, this option will take precendence.
`PreserveCase`, input, imtcp, boolean, `<module parameter>`, no, , 8.2106.0, , This permits to override the equally-named module parameter on the `input()` level. For further details, see the module parameter.
`PreserveCase`, module, imtcp, boolean, `on`, no, , 8.37.0, , This parameter is for controlling the case in `fromhost`. If `preservecase` is set to "`off`", the case in `fromhost` is not preserved. E.g., '`host1.example.org`' the message was received from '`Host1.Example.Org`'. Default to "`on`" for the backword compatibility.
`PreserveCase`, module, imudp, boolean, `off`, no, , 8.37.0, , This parameter is for controlling the case in `fromhost`. If `preservecase` is set to "`on`", the case in `fromhost` is preserved. E.g., '`Host1.Example.Org`' when the message was received from '`Host1.Example.Org`'. Default to "`off`" for the backward compatibility.
`ProcessOnPoller`, module, imptcp, binary, `on`, no, , , , Instructs imptcp to process messages on poller thread opportunistically. This leads to lower resource footprint(as poller thread doubles up as message-processing thread too). "`On`" works best when imptcp is handling low ingestion rates.
`Programkey`, action, imbatchreport, string, no, , , , , The attribute in structured data which contains the rsyslog APPNAME. This attribute has to be a String between double quotes (").
`promiscuous`, input, impcap, boolean, `off`, no, , , , When a valid interface is provided, sets the capture to promiscuous for this interface.
`pwd`, action, omclickhouse, word, , no, , , , Password for basic authentication.
`pwd`, action, omelasticsearch, word, , no, , , , Password for basic authentication.
`pwd`, action, omhttp
`PWD`, action, omlibdbi
`PWD`, action, ommysql
`PWD`, action, ompgsql
`queue.type`, ruleset, builtin
`ratelimit.burst`, action, omelasticsearch, integer, `20000`, no, , , , If retryfailures is not "on" (omelasticsearch-retryfailures) then this parameter has no effect.  
`ratelimit.burst`, action, omhttp, integer, `0`, no, , , , Specifies the rate-limiting burst in number of messages.
`RateLimit.Burst`, input, imhttp
`RateLimit.Burst`, input, imptcp, integer, `10000`, no, , , , Specifies the rate-limiting burst in number of messages.
`RateLimit.Burst`, input, imtcp, integer, `10000`, no, , , , Specifies the rate-limiting burst in number of messages. Default is 10,000. 
`RateLimit.Burst`, input, imudp, integer, `10000`, no, , 7.3.1, , Specifies the rate-limiting burst in number of messages.
`RateLimit.Burst`, input, imuxsock, integer, `200`, `2**32`, no, `$IMUXSockRateLimitBurst`, 5.7.1, , Specifies the rate-limiting burst in number of messages.
`Ratelimit.Burst`, module, imjournal, integer, `2000`, no, , 7.11.3, , Specifies the maximum number of messages that can be emitted within the ratelimit.interval interval. For further information, see description there.
`RatelimitBurst`, module, imklog, integer, `10000`, no, , 8.35.0, , Specifies the rate-limiting burst in number of messages. Set it high to preserve all bootup messages.
`ratelimit.interval`, action, omelasticsearch, integer, `600`, no, , , , If retryfailures is not "`on`" (`omelasticsearch-retryfailures`) then this parameter has no effect. Specifies the interval in seconds onto which rate-limiting is to be applied.
`ratelimit.interval`, action, omhttp
`RateLimit.Interval`, input, imhttp, integer, `0`, no, , , , Specifies the rate-limiting interval in seconds. Set it to a number of seconds to activate rate-limiting.
`RateLimit.Interval`, input, imptcp, integer, `0`, no, , , , Specifies the rate-limiting interval in seconds. Set it to a number of seconds (5 recommended) to activate rate-limiting.
`RateLimit.Interval`, input, imtcp, integer, `0`, no, , , , Specifies the rate-limiting interval in seconds. Default value is `0`, which turns off rate limiting. Set it to a number of seconds (5 recommended) to activate rate-limiting.
`RateLimit.Interval`, input, imudp, integer, `0`, no, , 7.3.1, , The rate-limiting interval in seconds. Value `0` turns off rate limiting. Set it to a number of seconds (5 recommended) to activate rate-limiting.
`RateLimit.Interval`, input, imuxsock, integer, `0`, no, `$IMUXSockRateLimitInterval`, , , Specifies the rate-limiting interval in seconds. Default value is `0`, which turns off rate limiting. Set it to a number of seconds (5 recommended) to activate rate-limiting. The default of 0 has been chosen as people experienced problems with this feature activated by default. 
`Ratelimit.Interval`, module, imjournal, integer, `600`, no, `$imjournalRatelimitInterval`, 7.11.3, , Specifies the interval in seconds onto which rate-limiting is to be applied. If more than ratelimit.burst messages are read during that interval, further messages up to the end of the interval are discarded. 
`RatelimitInterval`, module, imklog, integer, `0`, no, , 8.35.0, , The rate-limiting interval in seconds. Value `0` turns off rate limiting. Set it to a number of seconds (`5` recommended) to activate rate-limiting.
`RateLimit.Severity`, input, imuxsock, integer, `1`, no, `$IMUXSockRateLimitSeverity`, , , Specifies the severity of messages that shall be rate-limited.
`RcvBufSize`, input, imudp, size, , no, ,  7.3.9, , This request a socket receive buffer of specific size from the operating system. It is an expert parameter, which should only be changed for a good reason. Note that setting this parameter disables Linux auto-tuning, which usually works pretty well. The default value is 0, which means "keep the OS buffer size unchanged". This is a size value. So in addition to pure integer values, sizes like "256k", "1m" and the like can be specified. 
`readMode`, input, imfile, integer, `0`, no, `$InputFileReadMode`, , , This provides support for processing some standard types of multiline messages. It is less flexible than startmsg.regex or endmsg.regex but offers higher performance than regex processing. 
`readMode`, module, imkmsg, word, `full-boot`, no, , 8.2312.0, , This parameter permits to control when imkmsg reads the full kernel.
`readTimeout`, input, imfile, integer, `0`, no, , 8.23.0, , This sets the default value for input timeout parameters. See there for exact meaning. Parameter value is the number of seconds.
`readTimeout`, module, imfile
`rebindinterval`, action, omelasticsearch, integer, `-1`, no, , , , This parameter tells omelasticsearch to close the connection and reconnect to Elasticsearch after this many operations have been submitted. The default value -1 means that omelasticsearch will not reconnect. A value greater than -1 tells omelasticsearch, after this many operations have been submitted to Elasticsearch, to drop the connection and establish a new connection. 
`RebindInterval`, action, omrelp
`reconnectDelay`, action, omamqp1, integer, `5`, no, , 8.17.0, , The time in seconds this module will delay before attempting to re-established a failed connection to the message bus.
`recover_policy`, action, omrabbitmq
`reloadonhup`, action, omhttp
`Remote`, module, imjournal, binary, `off`, no, , 8.1910.0, , When this option is turned on, imjournal will pull not only all local journal files (default behavior), but also any journal files on machine originating from remote sources.
`Rename`, action, imbatchreport, string, no, `<regex><sent><reject>`, , , This parameter informs the module to rename the report to flag it as treated. The file is renamed using the `<regex>` to identify part of the file name that has to be replaced it: 1) by `<rename>` if the file was successfully treated; 2) by `<reject>` if the file is too large to be sent.
`reopenOnTruncate`, input, imfile, binary, `off`, no, , , , This is an experimental feature that tells rsyslog to reopen input file when it was truncated (inode unchanged but file size on disk is less than current offset in memory).
`replacementChar`, action, mmutf8fix, char, "` `", no, , 7.5.6, , This is the character that invalid sequences are replaced by. Currently, it MUST be a printable US-ASCII character.
`reportFailures`, action, omprog
`Reports`, action, imbatchreport, string, , `yes`, , , , Glob definition used to identify reports to manage.
`ResetCounters`, module, impstats, binary, `off`, no, , , , When set to "`on`", counters are automatically reset after they are emitted. In that case, the contain only deltas to the last value emitted. When set to "`off`", counters always accumulate their values.
`response`, input, mmdarwin, word, `no`, no, 7.0.0, , Tells the Darwin filter what to do next: * `no`: no response will be sent, nothing will be sent to next filter.; * `back`: a score for the input will be returned by the filter, nothing will be forwarded to the next filter.; * `darwin`: the data provided will be forwarded to the next filter (in the format specified in the filter's configuration), no response will be given to mmdarwin.; * `both`: the filter will respond to mmdarwin with the input's score AND forward the data (in the format specified in the filter's configuration) to the next filter.
`restpath`, action, omhttp
`resubmitOnFailure`, action, omkafka
`RetrieveNewLogsFromStart`, module, imdocker, binary, `1`, no, , 8.41.0, , This option specifies the whether imdocker will process newly found container logs from the beginning. The exception is for containers found on start-up. The container logs for containers that were active at imdocker start-up are controlled via '`GetContainerLogOptions`', the 'tail' in particular.
`retry`, action, omhttp
`retryfailures`, action, omelasticsearch, binary, `off`, no, , , , If this parameter is set to "`on`", then the module will look for an "`errors":true` in the bulk index response. If found, each element in the response will be parsed to look for errors, since a bulk request may have some records which are successful and some which are failures. 
`retryruleset`, action, omelasticsearch, word, , no, , , , If retryfailures is not "`on`" (`omelasticsearch-retryfailures`) then this parameter has no effect. This parameter specifies the name of a ruleset to use to route retries. 
`retry.ruleset`, action, omhttp
`rotation.sizeLimit`, action, omfile, size, `0`, no, `$OutChannel`, , , This permits to set a size limit on the output file. When the limit is reached, rotation of the file is tried. The rotation script needs to be configured via rotation.sizeLimitCommand.
`rotation.sizeLimitCommand`, action, omfile, binary, , no, `$OutChannel`, , , This permits to configure the script to be called whe a size limit on the output file is reached. The actual size limit needs to be configured via rotation.sizeLimit.
`routing_key`, action, omrabbitmq
`routing_key_template`, action, omrabbitmq
`rule`, action, mmnormalize, array, , no, , 8.26.0, , Contains an array of strings which will be put together as the rulebase. This parameter or rulebase MUST be given, because normalization can only happen based on a rulebase.
`ruleBase`, action, mmnormalize, word, , no, `$mmnormalizeRuleBase`, 6.1.2, , Specifies which rulebase file is to use. If there are multiple mmnormalize instances, each one can use a different file. However, a single instance can use only a single file. This parameter or rule MUST be given, because normalization can only happen based on a rulebase. It is recommended that an absolute path name is given. Information on how to create the rulebase can be found in the liblognorm manual.
`ruleset`, action, imdtls, word, , no, , 8.2402.0, , Determines the ruleset to which the imdtls input will be bound to. This can be overridden at the instance level., , , Specifies the mark message injection interval in seconds
`Ruleset`, action, imkafka, string, , no, , 8.27.0, , Specifies the ruleset to be used.
`ruleset`, input, builtin
`Ruleset`, input, imfile, string, , no, `$InputFileBindRuleset`, , , Binds the listener to a specific ruleset `<../../concepts/multi\_ruleset>`.
`ruleset`, input, imhiredis, word, , no, , , , Assign messages from this input to a specific Rsyslog ruleset.
`Ruleset`, input, imhttp, string, default ruleset, no, , , , Binds specified ruleset to this input. If not set, the default ruleset is bound.
`ruleset`, input, impcap, word, , no, , , , Assign messages from thi simput to a specific Rsyslog ruleset.
`Ruleset`, input, imptcp, string, , no, , , , Binds specified ruleset to this input. If not set, the default ruleset is bound.
`Ruleset`, input, imrelp, word, , no, `$InputRELPServerBindRuleset`, 7.5.0, , Binds the specified ruleset to all RELP listeners. This can be overridden at the instance level.
`Ruleset`, input, imtcp, string, , no, `$InputTCPServerBindRuleset`, , , Binds the listener to a specific ruleset `<../../concepts/multi_ruleset>`.
`Ruleset`, input, imudp, string, `RSYSLOG_DefaultRuleset`, , , , Binds the listener to a specific ruleset `<../../concepts/multi_ruleset>`.
`Ruleset`, input, imuxsock, string, `<default ruleset>`, no, , 8.17.0, , Binds specified ruleset to this input. If not set, the default ruleset is bound.
`Ruleset`, module, impstats, string, ,  no, , , , Binds the listener to a specific ruleset `<../../concepts/multi_ruleset>`.
`Ruleset`, module, imrelp, word, , no, `$InputRELPServerBindRuleset`, 7.5.0, , Binds the specified ruleset to all RELP listeners. This can be overridden at the instance level.
##RVRVR##`FileCreateMode`, input, imptcp, octalNumber, `0644`, no, , 7.3.11, , Set the access permissions for the state file. 
##RVRVR##`FileCreateMode`, module, imfile, file mode, `O0700`, no, `$FileCreateMode`, , , Sets the default `fileCreateMode` to be used for an action if no explicit one is specified.
##RVRVR##`FileGroup`, input, imptcp, GID, `<system default>`, no, , , , Set the group for the domain socket. The parameter is a group name, for which the groupid is obtained by rsyslogd during startup processing. Interim changes to the user mapping are not detected.
##RVRVR##`FileGroup`, module, imfile, GID, `<system default>`, no, `$FileGroup`, , , Sets the default fileGroup to be used for an action if no explicit one is specified.
##RVRVR##`FileGroupNum`, input, imptcp, integer, `<system default>`, no, , , , Set the group for the domain socket. The parameter is a numerical ID, which is used regardless of whether the group actually exists. This can be useful if the group mapping is not available to rsyslog during startup.
##RVRVR##`FileGroupNum`, module, imfile, integer, `<system default>`, no, , , , Sets the default fileGroupNum to be used for an action if no explicit one is specified.
##RVRVR##`FileOwner`, input, imfile, UID, `<process user>`, no, `$FileOwner`, , , Sets the default fileOwner to be used for an action if no explicit one is specified.
###RVRVR###`maxbytes`, action, omclickhouse
##RVRVR#`tls.AuthMode`, action, imdtls, string, , no, , 8.2402.0, , Sets the mode used for mutual authentication.  Supported values are either "fingerprint", "name" or "certvalid".
`SchedulingPolicy`, module, imudp, word, , no, `$IMUDPSchedulingPolicy`, , , Can be used the set the scheduler priority, if the necessary functionality is provided by the platform. Most useful to select "fifo" for real-time processing under Linux (and thus reduce chance of packet loss). Other options are "rr" and "other".
`SchedulingPriority`, module, imudp, integer, , no, `$IMUDPSchedulingPriority`, , , Scheduling priority to use.
`sd_id`, action, mmrfc5424addhmac, string, , no, , 7.5.6, , The RFC5424 structured data ID to be used by this module. This is the SD-ID that will be added. Note that nothing is added if this SD-ID is already present.
`sd_name.lowercase`, action, mmstructdata, boolean, `on`, no, , 8.32.0, , Specifies if sd names (SDID) shall be lowercased. If set to "`on`", this is the case, if "`off`" than not. The default of "`on`" is used because that was the traditional mode of operations. It it generally advised to change the parameter to "`off`" if not otherwise required.
`searchIndex`, action, omelasticsearch, word, `search`, no, , , , Elasticsearch index to send your logs to. Defaults to "`system`"
`searchType`, action, omelasticsearch, word, `events`, no, , , , Elasticsearch type to send your index to. Defaults to "events". Setting this parameter to an empty string will cause the type to be omitted, which is required since Elasticsearch 7.0.
`send_partial`, input, mmdarwin, boolean, `off`, no, , 7.0.0, , Whether to send to Darwin if not all :json:`"fields"` could be found in the message, or not.  All current Darwin filters required a strict number (and format) of parameters as input, so they will most likely not process the data if some fields are missing. This should be kept to "off", unless you know what you're doing.
`separator`, action, mmfields, char, "`,`", no, , 7.5.1, , This is the character used to separate fields. Currently, only a single character is permitted, while the RainerScript method permits to specify multi-character separator strings.
`Server`, action, omclickhouse, word, `localhost`, no, , , , The address of a ClickHouse server.
`Server`, action, omelasticsearch, array, `localhost`, no, , 8.2402.0, , An array of Elasticsearch servers in the specified format. If no scheme is specified, it will be chosen according to usehttps. If no port is specified, serverport will be used. Defaults to "`localhost`".
`Server`, action, omhiredis, ip, `127.0.0.1`, no, , , , The Redis server's IP to connect to.
`Server`, action, omhttp
`Server`, action, omlibdbi
`Server`, action, ommail
`Server`, action, ommysql
`Server`, action, ompgsql
`Server`, action, omsnmp
`server`, input, imhiredis
`ServerPassword`, action, omhiredis
`ServerPort`, action, omelasticsearch, integer, `9200`, no, , 8.2402.0, , Default HTTP port to use to connect to Elasticsearch if none is specified on a server. Defaults to `9200`
`ServerPort`, action, omhiredis
`ServerPort`, action, omhttp
`ServerPort`, action, ommysql
`Serverport`, action, ompgsql
`Severity`, action, imbatchreport, string, `notice`, no, , , , The syslog severity to be assigned to lines read. Can be specified in textual form (e.g. info, warning, ...) or as numbers (e.g. 6 for info). Textual form is suggested.
`Severity`, action, improg, string, `severity|number`, no, , , , The syslog severity to be assigned to lines read. Can be specified in textual form (e.g. `info`, `warning`, ...) or as numbers (e.g. `6` for `info`). Textual form is suggested.
`Severity`, action, imtuxedoulog, string, `[severity|number]`, no, , , , The syslog severity to be assigned to lines read. Can be specified in textual form (e.g. `info`, `warning`, ...) or as numbers (e.g. `6` for `info`). Textual form is suggested.
`Severity`, input, imfile, `notice`, no, `$InputFileSeverity`, 8.0, , The syslog severity to be assigned to lines read. Can be specified in textual form (e.g. `info`, `warning`, ...) or as numbers (e.g. `6` for `info`). Textual form is suggested. Default is `notice`.
`Severity`, module, impstats, integer, `6`, no, , , , The numerical syslog severity code to be used for generated messages. Default is `6` (`info`).This is useful for filtering messages.
`sig.aggregator.hmacAlg`, action, rsyslog-ksi-ls12
`sig.aggregator.key`, action, ksi
`sig.aggregator.uri`, action, ksi
`sig.aggregator.url`, action, rsyslog-ksi-ls12
`sig.aggregator.user`, action, ksi
`sig.aggregator.user`, action, rsyslog-ksi-ls12
`sig.block.keepRecordHashes`, action, gt
`sig.block.keepTreeHashes`, action, gt
`sig.block.levelLimit`, action, rsyslog-ksi-ls12
`sig.block.signTimeout`, action, rsyslog-ksi-ls12
`sig.block.sizeLimit`, action, gt
`sig.block.sizeLimit`, action, ksi
`sig.block.timeLimit`, action, rsyslog-ksi-ls12
`sig.confInterval`, action, rsyslog-ksi-ls12
`sig.debugFile`, action, rsyslog-ksi-ls12
`sig.debugLevel`, action, rsyslog-ksi-ls12
`sig.hashFunction`, action, gt
`sig.hashFunction`, action, ksi
`sig.hashFunction`, action, rsyslog-ksi-ls12
`sig.keepRecordHashes`, action, ksi
`sig.keepRecordhashes`, action, rsyslog-ksi-ls12
`sig.keepTreeHashes`, action, ksi
`sig.keepTreehashes`, action, rsyslog-ksi-ls12
`signalOnClose`, action, improg, binary, `off`, no, , , , Specifies whether a `TERM` signal must be sent to the external program before closing it (when either the worker thread has been unscheduled, a restart of the program is being forced, or rsyslog is about to shutdown).
`signalOnClose`, action, omprog
`sig.Provider`, action, omfile, word, , no, , , , Selects a signature provider for log signing. By selecting a provider, the signature feature is turned on.
`sig.provider`, action, rsyslog-ksi-ls12
`sig.randomSource`, action, rsyslog-ksi-ls12
`sig.syncmode`, action, rsyslog-ksi-ls12
`sig.timestampService`, action, gt
`skipPipelineIfEmpty`, action, omelasticsearch, binary, `off`, no, , , , When POST'ing a document, Elasticsearch does not allow an empty pipeline parameter value. If boolean option skipPipelineIfEmpty is set to "`on`", the pipeline parameter won't be posted. Default is "`off`".
`skipverifyhost`, action, omclickhouse, boolean, `off`, no, , , , If "`on`", this will set the curl `CURLOPT_SSL_VERIFYHOST` option to `0`. You are strongly discouraged to set this to "`on`". It is primarily useful only for debugging or testing.
`skipverifyhost`, action, omelasticsearch, boolean, `off`, no, , , , If "`on`", this will set the curl `CURLOPT_SSL_VERIFYHOST` option to `0`. You are strongly discouraged to set this to "`on`". It is primarily useful only for debugging or testing.
`skipverifyhost`, action, omhttp
`skipverifyhost`, module, mmkubernetes, boolean, `off`, no, , , , If "`on`", this will set the curl `CURLOPT_SSL_VERIFYHOST` option to `0`. You are strongly discouraged to set this to "`on`". It is primarily useful only for debugging or testing.
`snap_length`, module, impcap, number, `65535`, no, , , , Defines the maximum size of captured packets. If captured packets are longer than the defined value, they will be capped. Default value allows any type of packet to be captured entirely but can be much shorter if only metadata capture is desired (`500` to `2000` should still be safe, depending on network protocols). Be wary though, as impcap won't be able to parse metadata correctly if the value is not high enough.
`snmpTrapdSeverityMapping`, module, mmsnmptrapd, severity map, `warning`, no, `$mmSnmpTrapdSeverityMapping`, 5.8.1, , Tells the module which start string inside the tag to look for. The default is "`snmptrapd`". Note that a slash is automatically added to this tag when it comes to matching incoming messages. It MUST not be given, except if two slashes are required for whatever reasons (so "`tag/`" results in a check for "`tag//`" at the start of the tag field).
`snmpTrapdTag`, module, mmsnmptrapd, tag string, `snmptrapd`, no, `$mmSnmpTrapdTag`, 5.8.1, , Tells the module which start string inside the tag to look for. The default is "`snmptrapd`". Note that a slash is automatically added to this tag when it comes to matching incoming messages. It MUST not be given, except if two slashes are required for whatever reasons (so "`tag/`" results in a check for "`tag//`" at the start of the tag field).
`Snmpv1DynSource`, action, omsnmp
`Socket`, action, ommysql
`Socket`, action, omuxsock
`SocketBacklog`, input, imptcp, integer, `5`, no, , , , Specifies the backlog parameter sent to the `listen()` function. It defines the maximum length to which the queue of pending connections may grow. See man page of `listen(2)` for more information. The parameter controls both TCP and UNIX sockets backlog parameter. Default value is arbitrary set to `5`.
`Socket`, input, imuxsock, string, , no, `$AddUnixListenSocket`, , , Adds additional unixsocket.
`socketPath`, input, imhiredis, word,  `*`, no,  , , , Defines the socket to use when trying to connect to Redis. Will be ignored if both `imhiredis_server` and `imhiredis_socketPath` are given.
`SocketPath`, input, mmdarwin, word, , no, , 7.0.0, , The Darwin filter socket path to use.
`sortFiles`, module, imfile, binary, off, no, , 8.32.0, , If this parameter is set to on, the files will be processed in sorted order, else not. 
`Source`: https://www.rsyslog.com/doc/configuration/modules/omazureeventhubs.html
`SourcePort`.end, action, omudpspoof
`SourcePort`.start, action, omudpspoof
`SourceTemplate`, action, omudpspoof
`SpecificType`, action, omsnmp
`srcmetadatapath`, module, mmkubernetes, word, `$!metadata!filename`, no, , , , When reading json-file logs, with imfile and addmetadata="on", this is the property where the filename is stored.
`ssl`, action, omrabbitmq
`SSL_Ca`, action, ommongodb
`SSL_Cert`, action, ommongodb
`sslpartialchain`, module, mmkubernetes, boolean, off, no, , , , This option is only available if rsyslog was built with support for OpenSSL and only if the `X509_V_FLAG_PARTIAL_CHAIN` flag is available. If you attempt to set this parameter on other platforms, you will get an INFO level log message.
`startmsg.regex`, input, imfile, string, , no, , 8.10.0, , This permits the processing of multi-line messages. When set, a messages is terminated when the next one begins, and startmsg.regex contains the regex that identifies the start of a message. 
`statefile.directory`, module, imfile, string, global(WorkDirectory) value, no, , 8.1905.0, , This parameter permits to specify a dedicated directory for the storage of imfile state files. An absolute path name should be specified (e.g. /var/rsyslog/imfilestate). This permits to keep imfile state files separate from other rsyslog work items.
`StateFile`, module, imjournal, word, , no, `$imjournalStateFile`, 7.3.11, , This is a global setting. It specifies where the state file for persisting journal state is located. If a full path name is given (starting with "/"), that path is used. Otherwise the given name is created inside the working directory.
`statsFile`, action, omkafka
`statsname`, action, omazureeventhubs, word, `omazureeventhubs`, no, , 8.2301.0, , The name assigned to statistics specific to this action instance. The supported set of statistics tracked for this action instance are `submitted`, `accepted`, `failures` and `failures_other`. See the `statistics-counter_omazureeventhubs_label` section for more details.
`statsName`, action, omkafka
`stream.ack`, action, omhiredis
`stream.autoclaimIdelTime`, input, imhiredis, positive number, 0, no, , , , When using `imhiredis_stream_mode` with `imhiredis_stream_consumergroup` and `imhiredis_stream_consumername`, determines if the module should check for pending IDs that exceed this time (**in milliseconds**) to assume the original consumer failed to acknowledge the log and claim them for their own (see the redis ducumentation `<https://redis.io/docs/data-types/streams-tutorial/#automatic-claiming>`_ on this subject for more details on how that works). Has no influence in the other modes (queue or channel) and will be ignored.
`stream.capacityLimit`, action, omhiredis
`stream.consumerACK`, input, imhiredis, boolean, on, no, , , , When using :ref:`imhiredis_stream_mode` with :ref:`imhiredis_stream_consumergroup` and :ref:`imhiredis_stream_consumername`, determines if the module should directly acknowledge the ID once read from the Consumer Group. Has no influence in the other modes (queue or channel) and will be ignored.
`stream.consumerGroup`, input, imhiredis, word, , no, , , , When using the `imhiredis_stream_mode`, defines a consumer group name to use (see the `XREADGROUP` documentation `<https://redis.io/commands/xreadgroup/>`_ for details). This parameter activates the use of `XREADGROUP` commands, in replacement to simple `XREAD`s. Has no influence in the other modes (queue or channel) and will be ignored.
`stream.consumerName`, input, imhiredis, word, , no, , , , When using the `imhiredis_stream_mode`, defines a consumer name to use (see the `XREADGROUP` documentation `<https://redis.io/commands/xreadgroup/>`_ for details). This parameter activates the use of `XREADGROUP` commands, in replacement to simple `XREAD`s. Has no influence in the other modes (queue or channel) and will be ignored.
`stream.del`, action, omhiredis
`StreamDriver.AuthMode`, input, imtcp, string, `<module parameter>`, no, `$InputTCPServerStreamDriverAuthMode`, 8.2106.0, , This permits to override the equally-named module parameter on the `input()` level. For further details, see the module parameter.
`StreamDriver.AuthMode`, module, imtcp, string, , no, `$InputTCPServerStreamDriverAuthMode`, , , Sets stream driver authentication mode. Possible values and meaning depend on the network stream driver `<../../concepts/netstrm_drvr>`. used.
`StreamDriver.CAFile`, input, imtcp, string, `<global parameter>`, no, , 8.2108.0, , This permits to override the `DefaultNetstreamDriverCAFile` global parameter on the `input()` level. For further details, see the global parameter.
`streamDriver.CertFile`, input, imtcp, string, `<global parameter>`, no, , 8.2108.0, , This permits to override the DefaultNetstreamDriverCertFile global parameter on the `input()` level. For further details, see the global parameter.
`StreamDriver.CheckExtendedKeyPurpose`, input, imtcp, binary, `<module parameter>`, no, , 8.2016.0, , This permits to override the equally-named module parameter on the `input()` level. For further details, see the module parameter.
`StreamDriver.CheckExtendedKeyPurpose`, module, imtcp, binary, off, no, , , , Whether to check also purpose value in extended fields part of certificate for compatibility with rsyslog operation. (driver-specific)
`streamDriver.CRLFile`, input, imtcp, string, `<global parameter>`, no, , 8.2308.0, , This permits to override the CRL (Certificate revocation list) file set via `global()` config object at the per-action basis. This parameter is ignored if the netstream driver and/or its mode does not need or support certificates.
`streamDriver.KeyFile`, input, imtcp, string, `<global parameter>`, no, , 8.2108.0, , This permits to override the `DefaultNetstreamDriverKeyFile` global parameter on the `input()` level. For further details, see the global parameter.
`StreamDriver.Mode`, input, imtcp, integer, `<module parameter>`, no, `$InputTCPServerStreamDriverMode`, 8.2106.0, , This permits to override the equally-named module parameter on the `input()` level. For further details, see the module parameter.
`StreamDriver.Mode`, module, imtcp, integer, 0, no, `$InputTCPServerStreamDriverMode`, , , Sets the driver mode for the currently selected network stream driver `<../../concepts/netstrm_drvr>`. `<number>` is driver specific.
`StreamDriver.Name`, input, imtcp, string, `<module paramter>`, no, , 8.2106.0, , This permits to override the equally-named module parameter on the `input()` level. For further details, see the module parameter.
`StreamDriver.Name`, module, imtcp, string, , no, , , , Selects network stream driver `<../../concepts/netstrm_drvr>` for all inputs using this module.
`StreamDriver.PermitExpiredCerts`, input, imtcp, string, `<module parameter>`, no, , 8.2106.0, , This permits to override the equally-named module parameter on the `input()` level. For further details, see the module parameter.
`StreamDriver.PermitExpiredCerts`, module, imtcp, string, warn, no, , , , Controls how expired certificates will be handled when stream driver is in TLS mode. It can have one of the following values: on = Expired certificates are allowed; off = Expired certificates are not allowed (Default, changed from warn to off since Version 8.2012.0); warn = Expired certificates are allowed but warning will be logged
`StreamDriver.PrioritizeSAN`, input, imtcp, binary, `<module parameter>`, no, , 8.2106.0, , This permits to override the equally-named module parameter on the `input()` level. For further details, see the module parameter.
`StreamDriver.PrioritizeSAN`, module, imtcp, binary, off, no, , , , Whether to use stricter SAN/CN matching. (driver-specific)
`StreamDriver.TlsVerifyDepth`, input, imtcp, integer, `<module parameter>`, no, , 8.2106.0, , This permits to override the equally-named module parameter on the `input()` level. For further details, see the module parameter.
`StreamDriver.TlsVerifyDepth`, module, imtcp, integer, `<TLS library default>`, no, , , , Specifies the allowed maximum depth for the certificate chain verification. Support added in v8.2001.0, supported by GTLS and OpenSSL driver. If not set, the API default will be used. For OpenSSL, the default is 100
`stream.dynaKeyAck`, action, omhiredis
`stream.dynGroupAck`, action, omhiredis
`stream.dynIndexAck`, action, omhiredis
`stream.groupAck`, action, omhiredis
`stream.indexAck`, action, omhiredis
`stream.keyAck`, action, omhiredis
`stream.outField`, action, omhiredis
`stream.readFrom`, input, imhiredis, word, `$`, no, , , , When using the :ref:`imhiredis_stream_mode`, defines the starting ID `<https://redis.io/docs/data-types/streams-tutorial/#entry-ids>`_ for `XREAD`/`XREADGROUP` commands (can also use special IDs, see documentation `<https://redis.io/docs/data-types/streams-tutorial/#special-ids-in-the-streams-api>`). Has no influence in the other modes (queue or channel) and will be ignored.
`Subject.Template`, action, ommail
`Subject.Text`, action, ommail
`SupportOctetCountedFraming`, input, imhttp, binary, off, no, , , , Useful to send data using syslog style message framing, disabled by default. Message framing is described by RFC 6587 .
`SupportOctetCountedFraming`, input, imptcp, binary, on, no, , , , The legacy octed-counted framing (similar to RFC5425 framing) is activated. This is the default and should be left unchanged until you know very well what you do. It may be useful to turn it off, if you know this framing is not used and some senders emit multi-line messages into the message stream.
`SupportOctetCountedFraming`, input, imtcp, binary, on, no, `$InputTCPServerSupportOctetCountedFraming`, , , If set to "on", the legacy octed-counted framing (similar to RFC5425 framing) is activated. This should be left unchanged until you know very well what you do. It may be useful to turn it off, if you know this framing is not used and some senders emit multi-line messages into the message stream.
`sync`, action, omfile, binary, `off`, no, `$ActionFileEnableSync`, , , Enables file syncing capability of omfile.
`SysSock.Annotate`, module, imuxsock, binary, off, no, `$SystemLogSocketAnnotate`, , , Turn on annotation/trusted properties for the system log socket. See the imuxsock-trusted-properties-label section for more info.
`SysSock.FlowControl`, module, imuxsock, binary, off, no, `$SystemLogFlowControl`, , , Specifies if flow control should be applied to the system log socket.
`SysSock.IgnoreOwnMessages`, module, imuxsock, binary, on, no, , , , Ignores messages that originated from the same instance of rsyslogd. There usually is no reason to receive messages from ourselves. This setting is vital when writing messages to the systemd journal.
`SysSock.IgnoreTimestamp`, module, imuxsock, binary, on, no, `$SystemLogSocketIgnoreMsgTimestamp`, , , Ignore timestamps included in the messages, applies to messages received via the system log socket.
`SysSock.Name`, module, imuxsock, word, /dev/log, no, `$SystemLogSocketName`, , , Specifies an alternate log socket to be used instead of the default system log socket, traditionally /dev/log. Unless disabled by the SysSock.Unlink setting, this socket is created upon rsyslog startup and deleted upon shutdown, according to traditional syslogd behavior.
`SysSock.ParseHostname`, module, imuxsock, binary, off, no, , 8.9.0, , This option only has an effect if SysSock.UseSpecialParser is set to "off".
`SysSock.ParseTrusted`, module, imuxsock, binary, off, no, `$SystemLogParseTrusted`, 6.5.0, , If SysSock.Annotation is turned on, create JSON/lumberjack properties out of the trusted properties (which can be accessed via JSON Variables, e.g. `$!pid`) instead of adding them to the message.
`SysSock.RateLimit.Burst`, module, imuxsock, integer, 200, `2**32`, no, `$SystemLogRateLimitBurst`, 5.7.1, , Specifies the rate-limiting burst in number of messages.
`SysSock.RateLimit.Interval`, module, imuxsock, integer, 0, no, `$SystemLogRateLimitInterval`, , , Specifies the rate-limiting interval in seconds. Default value is 0, which turns off rate limiting. Set it to a number of seconds (5 recommended) to activate rate-limiting. The default of 0 has been chosen as people experienced problems with this feature activated by default. 
`SysSock.RateLimit.Severity`, module, imuxsock, integer, 1, no, `$SystemLogRateLimitSeverity`, , , Specifies the severity of messages that shall be rate-limited.
`SysSock.Unlink`, module, imuxsock, binary, on, no, , 7.3.9, , If turned on (default), the system socket is unlinked and re-created when opened and also unlinked when finally closed. Note that this setting has no effect when running under systemd control (because systemd handles the socket. See the imuxsock-systemd-details-label section for details.
`SysSock.Use`, module, imuxsock, binary, on, no, `$OmitLocalLogging`, , , Listen on the default local log socket (/dev/log) or, if provided, use the log socket value assigned to the SysSock.Name parameter instead of the default.
`SysSock.UsePIDFromSystem`, module, imuxsock, binary, off, no, `$SystemLogUsePIDFromSystem`, 5.7.0, , Specifies if the pid being logged shall be obtained from the log socket itself. If so, the TAG part of the message is rewritten. It is recommended to turn this option on, but the default is "off" to keep compatible with earlier versions of rsyslog.
`SysSock.UseSpecialParser`, module, imuxsock, binary, on, no, , 8.9.0, , The equivalent of the UseSpecialParser input parameter, but for the system socket. If turned on (the default) a special parser is used that parses the format that is usually used on the system log socket (the one syslog(3) creates). If set to "off", the regular parser chain is used, in which case the format on the log socket can be arbitrary.
`SysSock.UseSysTimeStamp`, module, imuxsock, binary, on, no, `$SystemLogUseSysTimeStamp`, 5.9.1, , The same as the input parameter UseSysTimeStamp, but for the system log socket. This parameter instructs imuxsock to obtain message time from the system (via control messages) instead of using time recorded inside the message. 
`Tag`, action, imbatchreport, yes, , , , , , The tag to be assigned to messages read from this file. If you would like to see the colon after the tag then you need to include it when you assign a tag value in like so: tag="myTagValue:".
`Tag`, action, improg, string, , yes, , , , The tag to be assigned to messages read from this file. If you would like to see the colon after the tag, you need to include it when you assign a tag value in like so: tag="myTagValue:".
`Tag`, action, imtuxedoulog, string, , yes, , The tag to be assigned to messages read from this file. If you would like to see the colon after the tag, you need to include it when you assign a tag value, like so: tag="myTagValue:".
`Tag`, action, mmtaghostname, string, , no, , , , The tag to be assigned to messages modified. If you would like to see the colon after the tag, you need to include it when you assign a tag value, like so: `tag="myTagValue:"`.  If this attribute is no provided, messages tags are not modified.
`Tag`, input, imfile, string, , yes, `$InputFileTag`, 8.0, , The tag to be assigned to messages read from this file. If you would like to see the colon after the tag, you need to include it when you assign a tag value, like so: tag="myTagValue:".
`tag`, input, impcap, word, , no, , , , Set a tag to messages coming from this input.
`Target`, action, omamqp1, word, , yes, , 8.17.0, , The destination for the generated messages. This can be the name of a queue or topic. On some messages buses it may be necessary to create this target manually. Example: “amq.topic”
`target`, action, omdtls, word, , no, , 8.2402.0, , Specifies the target hostname or IP address to send log messages to.
`Target`, action, omrelp
`Target`, action, omudpspoof
`Template`, action, omamqp1, word, `RSYSLOG_FileFormat`, yes, , 8.17.0, , Format for the log messages.
`template`, action, omazureeventhubs, word, `RSYSLOG_FileFormat`, no, , 8.2304.0, , Specifies the template used to format and structure the log messages that will be sent from rsyslog to Microsoft Azure Event Hubs.
`template`, action, omclickhouse, word, `StdClickHouseFmt`, no, , , , This is the message format that will be sent to ClickHouse. The resulting string needs to be a valid `INSERT` Query, otherwise ClickHouse will return an error. 
`Template`, action, omdtls, word, `RSYSLOG_TraditionalForwardFormat`, no, , 8.2402.0, , Sets a non-standard default template for this action instance.
`template`, action, omelasticsearch, word, `*`, no, , , , This is the JSON document that will be indexed in Elasticsearch. The resulting string needs to be a valid JSON, otherwise Elasticsearch will return an error. 
`Template`, action, omfile, word, `*`, no, `$ActionFileDefaultTemplate`, , , Sets the template to be used for this action.
`Template`, action, omhiredis
`template`, action, omhttp
`Template`, action, omhttpfs
`Template`, action, omjournal
`Template`, action, omkafka
`Template`, action, omlibdbi
`Template`, action, ommail
`Template`, action, ommongodb
`Template`, action, ommysql
`Template`, action, ompgsql
`template`, action, omprog
`Template`, action, omrelp
`template`, action, omstdout
`Template`, action, omudpspoof
`Template`, action, omusrmsg
`Template`, module, omdtls, word, `RSYSLOG_TraditionalForwardFormat`, no, `$ActionForwardDefaultTemplateName`, 8.2402.0, , Sets a non-standard default template for this module.
`Template`, module, omfile, word, `RSYSLOG_FileFormat`, no, `$ActionFileDefaultTemplate`, , , et the default template to be used if an action is not configured to use a specific template.
`Template`, module, omlibdbi
`template`, module, omudpspoof
`template`, ruleset, builtin
`Threads`, module, imptcp, integer, 2, no, , , , Number of helper worker threads to process incoming messages.  
`Threads`, module, imudp, integer, 1, no, , 7.5.5, , Number of worker threads to process incoming messages. These threads are utilized to pull data off the network. On a busy system, additional threads (but not more than there are CPUs/Cores) can help improving performance and avoiding message loss. Note that with too many threads, performance can suffer. There is a hard upper limit on the number of threads that can be defined. Currently, this limit is set to 32.
`timeout`, action, imdtls, word, 1800, no, , 8.2402.0, , Specifies the DTLS session timeout. As DTLS runs on transportless UDP protocol, there are no automatic detections of a session timeout. The input will close the DTLS session if no data is received from the client for the configured timeout period. The default is 1800 seconds which is equal to 30 minutes.
`timeout`, action, omclickhouse, integer, `0`, no, , , , This parameter sets the timeout for sending data to ClickHouse. Value is given in milliseconds.
`timeout`, action, omelasticsearch, word, `1m`, no, , , , How long Elasticsearch will wait for a primary shard to be available for indexing your log before sending back an error. Defaults to "`1m`".
`Timeout`, action, omrelp
`timeoutGranularity`, module, imfile, integer, 1, no, , 8.23.0, , This sets the interval in which multi-line-read timeouts are checked. The interval is specified in seconds. Note that this establishes a lower limit on the length of the timeout. 
`TimeRequery`, module, imudp, integer, 2, no, `$UDPServerTimeRequery`, , , This is a performance optimization. Getting the system time is very costly. With this setting, imudp can be instructed to obtain the precise time only once every n-times. This logic is only activated if messages come in at a very fast rate, so doing less frequent time calls should usually be acceptable. The default value is two, because we have seen that even without optimization the kernel often returns twice the identical time. You can set this value as high as you like, but do so at your own risk. The higher the value, the less precise the timestamp.
`Timestampkey`, action, imbatchreport, string, no, , , , , The attribute in structured data which contains the rsyslog TIMESTAMP. This attribute has to be a Number (Unix TimeStamp).
`TLS`, action, omrelp, 
`tls.AuthMode`, action, omdtls, string, , no, , 8.2402.0, , Sets the mode used for mutual authentication.  Supported values are either "`fingerprint`", "`name`" or "`certvalid`".
`TLS.AuthMode`, action, omrelp
`TLS.AuthMode`, input, imrelp, string, , no, , , , Sets the mode used for mutual authentication.  Supported values are either "fingerprint" or "name".
`tls.cacert`, action, omdtls, string, , no, , 8.2402.0, , The CA certificate that is being used to verify the client certificates. Has to be configured if tls.authmode is set to "fingerprint", "name" or "certvalid".
`tls.cacert`, action, omelasticsearch, word, , no, , , , This is the full path and file name of the file containing the CA cert for the CA that issued the Elasticsearch server cert. This file is in PEM format. For example: `/etc/rsyslog.d/es-ca.crt`
`tls.cacert`, action, omhttp
`TLS.CaCert`, action, omrelp
`TLS.CaCert`, input, imrelp, string, , no, , 8.2008.0, , The CA certificate that is being used to verify the client certificates. Has to be configured if TLS.AuthMode is set to "fingerprint" or "name".
`tls.cacert`, module, mmkuberneters, word, , no, , , , Full path and file name of file containing the CA cert of the Kubernetes API server cert issuer. Example: /etc/rsyslog.d/mmk8s-ca.crt. This parameter is not mandatory if using an http scheme instead of https in kubernetesurl, or if using allowunsignedcerts="yes".
`tls.cacert`, string, , no, , 8.2402.0, , The CA certificate that is being used to verify the client certificates. Has to be configured if tls.authmode is set to "fingerprint", "name" or "certvalid".
`TLS.Compression`, action, omrelp
`TLS.Compression`, input, imrelp, binary, off, no, , , , The controls if the TLS stream should be compressed (zipped). While this increases CPU use, the network bandwidth should be reduced. Note that typical text-based log records usually compress rather well.
`TLS.dhbits`, input, imrelp, integer, 0, no, , , , This setting controls how many bits are used for Diffie-Hellman key generation. If not set, the librelp default is used. For security reasons, at least 1024 bits should be used. Please note that the number of bits must be supported by GnuTLS. 
`TLS`, input, imrelp, binary, off, no, , 8.1903.0, , If set to "on", the RELP connection will be encrypted by TLS, so that the data is protected against observers. Please note that both the client and the server must have set TLS to either "on" or "off". 
`TLS`, input, imrelp, binary, off, no, , , , If set to "on", the RELP connection will be encrypted by TLS, so that the data is protected against observers. Please note that both the client and the server must have set TLS to either "on" or "off". 
`tls.mycert`, action, omdtls, string, , no, , 8.2402.0, , Specifies the certificate file used by omdtls. This certificate is presented to peers during the DTLS handshake.
`tls.mycert`, action, omelasticsearch, word, , no, , , , This is the full path and file name of the file containing the client cert for doing client cert auth against Elasticsearch. This file is in PEM format. For example: `/etc/rsyslog.d/es-client-cert.pem`
`tls.mycert`, action, omhttp
`TLS.MyCert`, action, omrelp
`TLS.MyCert`, input, imrelp, string, , no, , 8.2008.0, , The machine certificate that is being used for TLS communication.
`tls.mycert`, module, mmkubernetes, word, , no, , , , This is the full path and file name of the file containing the client cert for doing client cert auth against Kubernetes. This file is in PEM format. For example: `/etc/rsyslog.d/k8s-client-cert.pem`
`tls.mycert`, string, , no, , 8.2402.0, , Specifies the certificate file used by imdtls. This certificate is presented to peers during the DTLS handshake.
`tls.myprivkey`, action, omdtls, string, , no, , 8.2402.0, , The private key file corresponding to tls.mycert. This key is used for the cryptographic operations in the DTLS handshake.
`tls.myprivkey`, action, omelasticsearch, word, , no, , , , This is the full path and file name of the file containing the private key corresponding to the cert tls.mycert used for doing client cert auth against Elasticsearch. This file is in PEM format, and must be unencrypted, so take care to secure it properly. For example: `/etc/rsyslog.d/es-client-key.pem`
`tls.myprivkey`, action, omhttp
`TLS.MyPrivKey`, action, omrelp
`TLS.MyPrivKey`, input, imrelp, string, , no, , 8.2008.0, , The machine private key for the configured TLS.MyCert.
`tls.myprivkey`, module, mmkuberneters, word, , no, , , , This is the full path and file name of the file containing the private key corresponding to the cert tls.mycert used for doing client cert auth against Kubernetes. This file is in PEM format, and must be unencrypted, so take care to secure it properly. For example: /etc/rsyslog.d/k8s-client-key.pem 
`tls.myprivkey`, string, , no, , 8.2402.0, , The private key file corresponding to tls.mycert. This key is used for the cryptographic operations in the DTLS handshake.
`TLS.PermittedPeer`, action, omrelp
`TLS.PermittedPeer`, input, imrelp, array, , no, , , , PermittedPeer places access restrictions on this listener. Only peers which have been listed in this parameter may connect. The certificate presented by the remote peer is used for it's validation.
`TLS.PermittedPeer`, string, , no, , 8.2402.0, , PermittedPeer places access restrictions on this listener. Only peers which have been listed in this parameter may connect. The certificate presented by the remote peer is used for it's validation.
`TLS.PriorityString`, action, omrelp
`TLS.PriorityString`, input, imrelp, string, , no, , 8.2008.0, , This parameter allows passing the so-called "priority string" to GnuTLS. This string gives complete control over all crypto parameters, including compression settings. For this reason, when the prioritystring is specified, the "tls.compression" parameter has no effect and is ignored.
`tls.tlscfgcmd`, action, omdtls, string, , no, , 8.2402.0, , Used to pass additional OpenSSL configuration commands. This can be used to fine-tune the OpenSSL settings by passing configuration commands to the openssl library. 
`tls.tlscfgcmd`, action, omrelp
`TLS.tlscfgcmd`, input, imrelp, string, , no, , 8.2001.0, , The setting can be used if tls.tlslib is set to "openssl" to pass configuration commands to the openssl libray. OpenSSL Version 1.0.2 or higher is required for this feature. A list of possible commands and their valid values can be found in the documentation: `https://www.openssl.org/docs/man1.0.2/man3/SSL_CONF_cmd.html`
`tls.tlslib`, module, imrelp, word, , no, , 8.1903.0, , Permits to specify the TLS library used by librelp. All RELP protocol operations are actually performed by librelp and not rsyslog itself. The value specified is directly passed down to librelp. Depending on librelp version and build parameters, supported TLS libraries differ (or TLS may not be supported at all). In this case rsyslog emits an error message.
`tls.tlslib`, module, omrelp
`tokenfile`, module, mmkubernetes, word, , no, , , , The file containing the token to use to authenticate to the Kubernetes API server. One of tokenfile or token is required if Kubernetes is configured with access control. Example: /etc/rsyslog.d/mmk8s.token
`token`, module, mmkubernetes, word, , no, , , , The token to use to authenticate to the Kubernetes API server. One of token or tokenfile is required if Kubernetes is configured with access control. Example: `UxMU46ptoEWOSqLNa1bFmH`
`Topic`, action, imkafka, string, , yes, , 8.27.0, , Specifies the topic to produce to.
`Topic`, action, omkafka
`TopicConfParsm`, action, omkafka
`Transport`, action, omsnmp
`TrapOID`, action, omsnmp
`TrapType`, action, omsnmp
`trimLineOverBytes`, input, imfile, integer, 0, no, , , , This is used to tell rsyslog to truncate the line which length is greater than specified bytes. If it is positive number, rsyslog truncate the line at specified bytes. Default value of 'trimLineOverBytes' is 0, means never truncate line.
`tryResumeReopen`, action, ompipe
`type`, action, builtin
`type`, input, builtin
`type`, parser, builtin
`type`, ruleset, builtin
`uid`, action, omelasticsearch, word, , no, , , , If you have basic HTTP authentication deployed (eg through the elasticsearch-basic plugin), you can specify your user-name here.
`uid`, action, omhttp
`UID`, action, omlibdbi
`UID`, action, ommysql
`UID`, action, ompgsql
`ulogbase`, action, imtuxedoulog, string, `<path of ULOG file>`, yes, , , , Path of ULOG file as it is defined in Tuxedo Configuration ULOGPFX. Dot and date is added a end to build full file path
`Unlink`, input, imptcp , binary, off, no, , , , If a unix domain socket is being used this controls whether or not the socket is unlinked before listening and after closing.
`Unlink`, input, imuxsock, binary, on, no, none, 7.3.9, , If turned on (default), the socket is unlinked and re-created when opened and also unlinked when finally closed. Set it to off if you handle socket creation yourself.
`UriStr`, action, ommongodb
`usehttps`, action, omclickhouse, binary, `on`, no, , , , Default scheme to use when sending events to ClickHouse if none is specified on a server.
`usehttps`, action, omelasticsearch, binary, `off`, no, , , , Default scheme to use when sending events to Elasticsearch if none is specified on a server. Good for when you have Elasticsearch behind Apache or something else that can add HTTPS. 
`useHttps`, action, omhttp
`uselpop`, input, imhiredis, boolean, no, no, , , , When using the `imhiredis_queue_mode`, defines if imhiredis should use a LPOP instruction instead of a RPOP (the default).  Has no influence on the `imhiredis_channel_mode` and will be ignored if set with this mode.
`UsePIDFromSystem`, input, imuxsock, binary, off, no, `$InputUnixListenSocketUsePIDFromSystem`, , , Specifies if the pid being logged shall be obtained from the log socket itself. If so, the TAG part of the message is rewritten. It is recommended to turn this option on, but the default is "`off`" to keep compatible with earlier versions of rsyslog.
`UsePidFromSystem`, module, imjournal, binary, 0, no, , 7.11.3, , Retrieves the trusted systemd parameter, `_PID`, instead of the user systemd parameter, `SYSLOG_PID`, which is the default. This option override the "usepid" option. This is now deprecated. It is better to use `usepid="syslog"` instead.
`UsePid`, module, imjournal, string, both, no, , 7.11.3, , Sets the PID source from journal.  'syslog': imjournal retrieves `SYSLOG_PID` from journal as PID number.  system: imjournal retrieves `_PID` from journal as PID number.  both:  imjournal trying to retrieve `SYSLOG_PID` first. When it is not available, it is also trying to retrieve `_PID`. When none of them is available, message is parsed without PID number.
`user`, action, omclickhouse, word, `default`, no, , , , If you have basic HTTP authentication deployed you can specify your user-name here.
`User`, action, omhttpfs
`user`, action, ompgsql
`user`, action, omrabbitmq
`useRawMsg`, action, mmjsonparse, binary, off, no, , 6.6.0, , Specifies if the raw message should be used for normalization (on) or just the MSG part of the message (off).
`useRawMsg`, action, mmnormalize, boolean, `off`, no, `$mmnormalizeUseRawMsg`, 6.1.3, , Specifies if the raw message should be used for normalization (on) or just the MSG part of the message (off).
`Username`, action, omamqp1, word, , no, , 8.17.0, , The destination for the generated messages. This can be the name of a queue or topic. On some messages buses it may be necessary to create this target manually. Example: "`amq.topic`"
`Userpush`, action, omhiredis
`Users`, action, omusrmsg
`UseSpecialParser`, input, imuxsock, binary, on, no, , 8.9.0, , Equivalent to the SysSock.UseSpecialParser module parameter, but applies to the input that is being defined.
`UseSysTimeStamp`, input, imuxsock, binary, on, no, `$InputUnixListenSocketUseSysTimeStamp`, 5.9.1, , This parameter instructs imuxsock to obtain message time from the system (via control messages) instead of using time recorded inside the message. 
`useTransactions`, action, omprog
`value`, action, mmcount, 7.5.0, ,
`variable`, action, mmnormalize, word, , no, , 8.5.1, , Specifies if a variable insteed of property 'msg' should be used for normalization. A variable can be property, local variable, json-path etc. Please note that useRawMsg overrides this parameter, so if useRawMsg is set, variable will be ignored and raw message will be used.
`verify_hostname`, action, omrabbitmq
`verify_peer`, action, omrabbitmq
`veriyRobustZip`, action, omfile, binary, `off`, no, , 7.3.0, , If zipLevel is greater than 0, then this setting controls if extra headers are written to make the resulting file extra hardened against malfunction.
`Version`, action, omsnmp
`virtual_host`, action, omrabbitmq
`WindowSize`, action, omrelp
`WorkaroundJournalBug`, module, imjournal, binary, on, no, , 8.37.0, 8.1910.0 , Deprecated. This option was intended as temporary and has no effect now (since 8.1910.0). Left for backwards compatibility only.
`writeoperation`, action, omelasticsearch, word, `index`, no, , , , The value of this parameter is either "`index`" (the default) or "`create`". If "`create`" is used, this means the bulk action/operation will be create - create a document only if the document does not already exist. The record must have a unique id in order to use create. See `omelasticsearch-bulkid` and `omelasticsearch-dynbulkid`.. 
`zipLevel`, action, omfile, integer, `0`, no, `$OMFileZipLevel`, , , If greater than 0, turns on gzip compression of the output file. The higher the number, the better the compression, but also the more CPU is required for zipping.
