MIDIClient.init;
MIDIIn.connectAll;



(
~vibrato_strat = 2;


~bend = 8192;
~is_vibrato = 0;
~vibrato_accel = 0;

MIDIdef.noteOn(\noteonTest, {
	arg vel, nn, chan, src;
	[vel, nn].postln;
	if (nn == 25, {
		~is_vibrato = 1;
		~vibrato_accel = vel;
		~notes.do{arg synth; synth.set(\is_vibrato, 1); synth.set(\vibrato_accel, vel)};
	},{
		~notes[nn] = Synth.new(
			\tone,
			[
				\freq, nn.midicps,
				\amp, vel.linexp(1,127,0.01,0.3),
				\gate, 1,
				\bend, ~bend.linlin(0,16383, -2,2),
				\is_vibrato, ~is_vibrato,
				\vibrato_accel, ~vibrato_accel,
			]
		);
	});
});

MIDIdef.noteOff(\noteOffTest, {
	arg vel, nn;
	if ((~vibrato_strat == 1) && (nn == 25), {
		~is_vibrato = 0;
		~notes.do{arg synth; synth.set(\is_vibrato, 0)};
	},{
		if (~vibrato_strat == 2, {~is_vibrato = 0}, {});
		~notes[nn].set(\gate, 0);
		~notes[nn] = nil;
	})
});

MIDIdef.bend(\bendTest, {
	arg val, chan, src;
	[val, chan, src].postln;
	~bend = val;
	~notes.do{arg synth; synth.set(\bend, val.linlin(0,16383, -2, 2))};
});
)


(
SynthDef.new(\tone, {
	arg freq=440, amp=0.3, gate=0, bend = 0, is_vibrato = 0, vibrato_accel = 0;
	var sig, env, vib;
	if ((~vibrato_strat == 1), {
		// Make cool function which reaches asymptote of 0.03
		vib = -0.03*is_vibrato/((vibrato_accel/240+0.05)*Sweep.kr(0, 1)+1) + (0.03*is_vibrato);
	},{
		vib = is_vibrato*(vibrato_accel/3000);
	});
	sig = LFSaw.ar(Vibrato.kr(freq * bend.midiratio,8, vib))!2;
	env = EnvGen.kr(Env.adsr(0.01, 0.3, 0.5, 0.3), gate, doneAction:2);
	sig = sig * env * amp;
	Out.ar(0, sig);
}).add;
)

x = Synth.new(\tone, [\gate, 1]);
x.set(\gate, 0);

~notes = Array.newClear(128);


s.boot;
