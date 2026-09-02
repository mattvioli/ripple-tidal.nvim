// TidalLooper — Live sampling for SuperDirt
// Ported from https://github.com/thgrund/tidal-looper
//
// Configurable via environment variables (set before loading):
//   ~numBuffers (default: 8)
//   ~linput     (default: 0)
//   ~lname      (default: "loop")
//   ~path       (default: "~/Music/Loops/")
//   ~pLevel     (default: 0.0)  — 0.0 = replace, 1.0 = overdub
//   ~rLevel     (default: 2.5)
//   ~latencyFineTuning (default: 0.04)
//   ~debugMode  (default: false)

~numBuffers = ~numBuffers ?? 8;
~linput = ~linput ?? 0;
~lname = ~lname ?? "loop";
~path = ~path ?? "~/Music/Loops/";
~pLevel = ~pLevel ?? 0.0;
~rLevel = ~rLevel ?? 2.5;
~latencyFineTuning = ~latencyFineTuning ?? 0.04;
~debugMode = ~debugMode ?? false;

SynthDef(\buffRecord, {|input = 0, pLevel = 0.0, buffer|
	var in = SoundIn.ar(input);
	RecordBuf.ar(in, buffer, recLevel: 0.85, preLevel: pLevel, loop:0, run: 1, doneAction: Done.freeSelf);
}).add;

~synths = ~synths ?? ();

~synths[\loopValues] = {
	if (~linput.isNil) {~linput = 0};
	if (~lname.isNil) {~lname = "loop"};
	if (~n == \none, {~n = 0.0});
	if (~debugMode) { ("looper: linput=" ++ ~linput ++ " lname=" ++ ~lname ++ " n=" ++ ~n).postln };
};

~synths[\looper] = {
	var newBuffer;
	var modN;
	var bufferEvent;

	~synths[\loopValues].value;

	modN = ~n % ~numBuffers;

	newBuffer = Buffer.alloc(~dirt.server, ~dirt.server.sampleRate * (~delta.value),1);

	if (~dirt.soundLibrary.buffers[~lname.asSymbol].size != ~numBuffers, {
		~numBuffers.do({
			~dirt.soundLibrary.addBuffer(
				~lname.asSymbol,
				Buffer.alloc(~dirt.server, 0, 1),
				true
			);
		});
	});

	~dirt.server.makeBundle(~latency + 0.01, {
		if (~pLevel == 0.0, {
			// Replace mode
			if (~dirt.soundLibrary.buffers[~lname.asSymbol].at(modN).notNil {
				~dirt.soundLibrary.buffers[~lname.asSymbol].at(modN).free
			});

			bufferEvent = ~dirt.soundLibrary.makeEventForBuffer(newBuffer);
			~dirt.soundLibrary.buffers[~lname.asSymbol].put(modN, newBuffer);
			~dirt.soundLibrary.bufferEvents[~lname.asSymbol].put(modN, bufferEvent);
		}, {
			// Overdub mode
			if (~dirt.soundLibrary.buffers[~lname.asSymbol].at(modN).duration == 0.0, {
				~dirt.soundLibrary.buffers[~lname.asSymbol].at(modN).free;
				bufferEvent = ~dirt.soundLibrary.makeEventForBuffer(newBuffer);
				~dirt.soundLibrary.buffers[~lname.asSymbol].put(modN, newBuffer);
				~dirt.soundLibrary.bufferEvents[~lname.asSymbol].put(modN, bufferEvent);
			});
		});
	});

	q = Routine {
		(~latency + ~latencyFineTuning).wait;
		Synth(\buffRecord,
			[input: ~linput, pLevel: ~pLevel, buffer: ~dirt.soundLibrary.buffers[~lname.asSymbol][modN]],
			~dirt.server
		);
	}.play;
};

~synths[\olooper] = {
	var savedLevel = ~pLevel;
	~pLevel = 1.0;
	~synths[\looper].value;
	~pLevel = savedLevel;
};

~synths[\rlooper] = {
	var savedLevel = ~pLevel;
	~pLevel = 0.0;
	~synths[\looper].value;
	~pLevel = savedLevel;
};

~synths[\slooper] = {
	var modN;
	~synths[\loopValues].value;
	modN = ~n % ~numBuffers;
	if (~dirt.soundLibrary.buffers[~lname.asSymbol].at(modN).duration == 0.0, {
		~synths[\rlooper].value;
	});
};

~synths[\freeLoops] = {
	~synths[\loopValues].value;
	~dirt.soundLibrary.freeSoundFiles(~lname.asSymbol);
};

~synths[\persistLoops] = {
	var abspath;

	~synths[\loopValues].value;

	abspath = ~path.standardizePath ++ ~lname.asSymbol;

	File.mkdir(abspath);

	~numBuffers.do({ |index|
		~dirt.soundLibrary.buffers[~lname.asSymbol][index].write(
			abspath ++ "/" ++ index ++ ".aiff"
		)
	})
};

~synths.keysValuesDo{ |key, func|  ~dirt.soundLibrary.addSynth( key, (play: func)) };

if (~debugMode) { "TidalLooper loaded: % synths added".format(~synths.size).postln };
