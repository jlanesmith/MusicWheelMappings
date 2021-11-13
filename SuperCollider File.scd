MIDIClient.init;
MIDIIn.connectAll;

o = Server.default.options;
o.inDevice_("Windows WASAPI : Microphone");
o.outDevice_("Windows WASAPI : Speakers");

(
~vibrato_key = 25;
~bend_keys = [21, 23, 24, 26];

~vibrato_strat = 2;
~is_vibrato = 0;
~vibrato_speed = 0;

~bend_strat = 1;

MIDIdef.noteOn(\noteonTest, {
	arg vel, nn, chan, src, bend_speed;
	[vel, nn].postln;
	bend_speed = max(2 - (vel/56), 0); // Make it easier to get fast bending
	if (~bend_keys.includes(nn), {
		switch(nn,
			~bend_keys[0], {~notes.do{arg synth; synth.set(\bend_final, -2); synth.set(\bend_speed, bend_speed)}},
			~bend_keys[1], {~notes.do{arg synth; synth.set(\bend_final, -1); synth.set(\bend_speed, bend_speed)}},
			~bend_keys[2], {~notes.do{arg synth; synth.set(\bend_final, 1); synth.set(\bend_speed, bend_speed)}},
			~bend_keys[3], {~notes.do{arg synth; synth.set(\bend_final, 2); synth.set(\bend_speed, bend_speed)}}
		)
	}, {});

	if (nn == ~vibrato_key, {
		~is_vibrato = 1;
		~vibrato_speed = vel;
		~notes.do{arg synth; synth.set(\is_vibrato, 1); synth.set(\vibrato_speed, ~vibrato_speed)};
	},{});


	if (nn > ~bend_keys[3], {
		~notes[nn] = Synth.new(
			\tone,
			[
				\freq, nn.midicps,
				\amp, vel.linexp(1,127,0.01,0.3),
				\gate, 1,
				\bend_final, 0,
				\is_vibrato, ~is_vibrato,
				\vibrato_speed, ~vibrato_speed,
			]
		);
	}, {});
});

MIDIdef.noteOff(\noteOffTest, {
	arg vel, nn;
	if ((~vibrato_strat == 1) && (nn == ~vibrato_key), {
		~is_vibrato = 0;
		~notes.do{arg synth; synth.set(\is_vibrato, 0)};
	},{});

	if ((~vibrato_strat == 2) && (nn == ~vibrato_key), {~is_vibrato = 0}, {});

	if (~bend_keys.includes(nn), {
		switch(nn,
			~bend_keys[0], {~notes.do{arg synth; synth.set(\bend_final, 0)}},
			~bend_keys[1], {~notes.do{arg synth; synth.set(\bend_final, 0)}},
			~bend_keys[2], {~notes.do{arg synth; synth.set(\bend_final, 0)}},
			~bend_keys[3], {~notes.do{arg synth; synth.set(\bend_final, 0)}}
		)
	}, {});

	~notes[nn].set(\gate, 0);
	~notes[nn] = nil;
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
	arg freq=440, amp=0.3, gate=0, bend_final = 0, bend_speed = 0, is_vibrato = 0, vibrato_speed = 0;
	var sig, env, vib, bend;
	if ((~vibrato_strat == 1), {
		// Make cool function which reaches asymptote of 0.03
		vib = -0.03*is_vibrato/((vibrato_speed/240+0.05)*Sweep.kr(0, 1)+1) + (0.03*is_vibrato);
	},{
		vib = is_vibrato*vibrato_speed/3000;
	});

	bend = bend_final.lag(bend_speed);

	sig = LFPulse.ar(Vibrato.kr(freq * bend.midiratio, 8, vib))!2;
	env = EnvGen.kr(Env.adsr(0.01, 0.3, 0.5, 0.3), gate, doneAction:2);
	sig = sig * env * amp;
	Out.ar(0, sig);
}).add;
)

x = Synth.new(\tone, [\gate, 1]);
x.set(\gate, 0);

~notes = Array.newClear(128);


s.boot;
