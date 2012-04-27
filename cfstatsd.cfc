<!--- 
Copyright (c) 2011-2012 Matthew Walker

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the 'Software'), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 --->

<!--- 
cfstatsd is a ColdFusion client for StatsD (https://github.com/etsy/statsd)

More info on StatsD:

http://codeascraft.etsy.com/2011/02/15/measure-anything-measure-everything/

Use it as follows:

<cfset statsd = CreateObject("component","cfstatsd").init('statsd.example.com', 8125) />

<cfset statsd.increment("testing.cf.increment") />
<cfset statsd.increment("testing.cf.increment-magnitude", 10) />
<cfset statsd.increment("testing.cf.increment-sampled", 1, .2) />
<cfset statsd.incrementMulti(1, 1, "testing.cf.increment-1", "testing.cf.increment-2", "testing.cf.increment-3") />

<cfset statsd.decrement("testing.cf.decrement") />
<cfset statsd.decrement("testing.cf.decrement-magnitude", 10) />
<cfset statsd.decrement("testing.cf.decrement-sampled", 1, .2) />
<cfset statsd.decrementMulti(1, 1, "testing.cf.decrement-1", "testing.cf.decrement-2", "testing.cf.decrement-3") />

<cfset statsd.timing("testing.cf.timing", 1024) />
<cfset statsd.timing("testing.cf.timing-sampled", 1024, .2) />

<cfset statsd.gauge("testing.cf.gauge", 8675) />

Cheers!
 --->

<cfcomponent name="cfstatsd" displayname="statsd controller" hint="This CFC handles communication with a statsd daemon">

	<cfset this.host = "">
	<cfset this.port = "">
	<cfset this._channel = "">
	<cfset this._address = "">


	<cffunction name="init" access="public" returntype="Any" output="no">
		<cfargument name="host" type="string" required="true" />
		<cfargument name="port" type="numeric" required="false" default="8125" />

		<cfset this.host = arguments.host />
		<cfset this.port = arguments.port />	

		<cfset this._channel = createObject('java','java.nio.channels.DatagramChannel').open() />
		<cfset _host = createObject('java','java.net.InetAddress').getByName(this.host) />
		<cfset this._address = createObject('java','java.net.InetSocketAddress').init(_host,this.port) />

		<cfreturn this>
	</cffunction>


	<cffunction name="increment" access="public" returntype="boolean" output="no">
		<cfargument name="key" type="string" required="true" />
		<cfargument name="magnitude" type="numeric" required="false" default="1" />
		<cfargument name="sampleRate" type="numeric" required="false" default="1" />
		
		<cfreturn incrementMulti(arguments.magnitude, arguments.sampleRate, arguments.key) />
	</cffunction>


	<cffunction name="incrementMulti" access="public" returntype="boolean" output="no">
		<cfargument name="magnitude" type="numeric" required="true" />
		<cfargument name="sampleRate" type="numeric" required="true" />
		<cfargument name="keys" type="any" required="true" />
		
		<!--- Treat non-named arguments as java-style varargs arguments (ex. String... stats) --->
		<cfset namedArgumentCount = 3 />
		<cfset keysArray = ArrayNew(1) />
		<cfif isArray(arguments.keys)>
			<cfset keysArray = arguments.keys />
		<cfelseif isSimpleValue(arguments.keys)>
			<cfset ArrayAppend(keysArray, arguments.keys) />
			<cfif ArrayLen(arguments) GT namedArgumentCount>
				<cfloop from="#(namedArgumentCount + 1)#" to="#ArrayLen(arguments)#" index="i">
					<cfif isSimpleValue(arguments[i])>
						<cfset ArrayAppend(keysArray, arguments[i]) />
					</cfif>
				</cfloop>
			</cfif>
		<cfelse>
			<cfthrow type="InvalidArgumentTypeException" 
				message="The keys argument passed to the incrementMulti method is not an array or one or more strings." />
		</cfif>

		<cfset stats = ArrayNew(1) />
		<cfloop from="1" to="#arrayLen(keysArray)#" index="i">
			<cfset ArrayAppend(stats, keysArray[i] & ":" & arguments.magnitude & "|c") />
		</cfloop>

		<cfreturn send(arguments.sampleRate, stats) />
	</cffunction>


	<cffunction name="decrement" access="public" returntype="boolean" output="no">
		<cfargument name="key" type="string" required="true" />
		<cfargument name="magnitude" type="numeric" required="false" default="1" />
		<cfargument name="sampleRate" type="numeric" required="false" default="1" />
		
		<cfreturn decrementMulti(arguments.magnitude, arguments.sampleRate, arguments.key) />
	</cffunction>


	<cffunction name="decrementMulti" access="public" returntype="boolean" output="no">
		<cfargument name="magnitude" type="numeric" required="true" />
		<cfargument name="sampleRate" type="numeric" required="true" />
		<cfargument name="keys" type="any" required="true" />
		
		<!--- Treat non-named arguments as java-style varargs arguments (ex. String... stats) --->
		<cfset namedArgumentCount = 3 />
		<cfset keysArray = ArrayNew(1) />
		<cfif isArray(arguments.keys)>
			<cfset keysArray = arguments.keys />
		<cfelseif isSimpleValue(arguments.keys)>
			<cfset ArrayAppend(keysArray, arguments.keys) />
			<cfif ArrayLen(arguments) GT namedArgumentCount>
				<cfloop from="#(namedArgumentCount + 1)#" to="#ArrayLen(arguments)#" index="i">
					<cfif isSimpleValue(arguments[i])>
						<cfset ArrayAppend(keysArray, arguments[i]) />
					</cfif>
				</cfloop>
			</cfif>
		<cfelse>
			<cfthrow type="InvalidArgumentTypeException" 
				message="The keys argument passed to the decrementMulti method is not an array or one or more strings." />
		</cfif>

		<cfif arguments.magnitude GT 0>
			<cfset arguments.magnitude = -arguments.magnitude />
		</cfif>

		<cfreturn incrementMulti(arguments.magnitude, arguments.sampleRate, keysArray) />
	</cffunction>


	<cffunction name="timing" access="public" returntype="boolean" output="no">
		<cfargument name="key" type="string" required="true" />
		<cfargument name="value" type="numeric" required="true" />
		<cfargument name="sampleRate" type="numeric" required="false" default="1" />

		<cfreturn send(arguments.sampleRate, arguments.key & ":" & arguments.value & "|ms") />
	</cffunction>


	<cffunction name="gauge" access="public" returntype="boolean" output="no">
		<cfargument name="key" type="string" required="true" />
		<cfargument name="value" type="numeric" required="true" />

		<cfreturn send(1.0, arguments.key & ":" & arguments.value & "|g") />
	</cffunction>


	<cffunction name="send" access="private" returntype="boolean" output="no">
		<cfargument name="sampleRate" type="numeric" required="true" />
		<cfargument name="stats" type="any" required="true" />
		
		<!--- Treat non-named arguments as java-style varargs arguments (ex. String... stats) --->
		<cfset namedArgumentCount = 2 />
		<cfset statsArray = ArrayNew(1) />
		<cfif isArray(arguments.stats)>
			<cfset statsArray = arguments.stats />
		<cfelseif isSimpleValue(arguments.stats)>
			<cfset ArrayAppend(statsArray, arguments.stats) />
			<cfif ArrayLen(arguments) GT namedArgumentCount>
				<cfloop from="#(namedArgumentCount + 1)#" to="#ArrayLen(arguments)#" index="i">
					<cfif isSimpleValue(arguments[i])>
						<cfset ArrayAppend(statsArray, arguments[i]) />
					</cfif>
				</cfloop>
			</cfif>
		<cfelse>
			<cfthrow type="InvalidArgumentTypeException" 
				message="The stats argument passed to the send method is not an array or one or more strings." />
		</cfif>

		<cfscript>
			// this code borrows heavily from StatsdClient.java
			retval = false;
			if (arguments.sampleRate LT 1.0) {
				for (i = 1; i LTE ArrayLen(statsArray); i = i + 1) {
					if (rand() LTE sampleRate) {
						stat = statsArray[i] & "|@" & arguments.sampleRate;
						if (doSend(stat)) {
							retval = true;
						}
					}
				}
			} else {
				for (i = 1; i LTE ArrayLen(statsArray); i = i + 1) {
					if (doSend(statsArray[i])) {
						retval = true;
					}
				}
			}
			return retval;
		</cfscript>
	</cffunction>


	<cffunction name="doSend" access="private" returntype="boolean" output="no">
		<cfargument name="stat" type="string" required="true" />

		<cftry>
			<cfset data = arguments.stat.getBytes("utf-8") />
			<cfset byteBuffer = createObject('java','java.nio.ByteBuffer') />
			<cfset buff = byteBuffer.wrap(data) />
			<cfset nbSentBytes = this._channel.send(buff, this._address) />

			<cfif nbSentBytes EQ Len(data)>
				<cfreturn true />
			<cfelse>
				<cflog text="cfstatsd: Could not entirely send stat #arguments.stat# to host #this.host#:#this.port#.  Only sent #nbSentBytes# out of #Len(data)# bytes" type="Warning" log="Application" />
			</cfif>

			<cfcatch type="Any">
				<cflog text="cfstatsd: Could not send stat #arguments.stat# to host #this.host#:#this.port#" type="Warning" log="Application" />
			</cfcatch>			
		</cftry>

		<cfreturn false />
	</cffunction>

</cfcomponent>
