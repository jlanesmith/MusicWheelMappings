MIDIClient.init;
MIDIIn.connectAll;

o = Server.default.options;
o.inDevice_("Windows WASAPI : Microphone");
o.outDevice_("Windows WASAPI : Speakers");

(
~vibrato_strat = 2;
~bend_strat = 1;

~vibrato_key = 25;
~vibrato_off_key = 27;
~bend_keys_1 = [21, 23, 26, 28];
~bend_keys_2 = [21, 23, 24, 26, 28];

~is_vibrato = 0;
~vibrato_speed = 0;
~initial_key = -1; // 0 to 4, for bending strat 2

// Values for bend_strat 2
~bend_value_array_0 = [0,-0.5,-1,-1.5,-2];
~bend_value_array_1 = [0.5,0,-0.5,-1,-1.5];
~bend_value_array_2 = [1,0.5,0,-0.5,-1];
~bend_value_array_3 = [1.5,1,0.5,0,-0.5];
~bend_value_array_4 = [2,1.5,1,0.5,0];


MIDIdef.noteOn(\noteonTest, {
	arg vel, nn, chan, src, bend_speed;
	[vel, nn].postln;

	// Vibrato
	if (nn == ~vibrato_key, {
		~is_vibrato = 1;
		~vibrato_speed = vel;
		~notes.do{arg synth; synth.set(\is_vibrato, 1); synth.set(\vibrato_speed, ~vibrato_speed)};
	},{});
	if (nn == ~vibrato_off_key, {
		~is_vibrato = 0;
		~notes.do{arg synth; synth.set(\is_vibrato, 0)};
	},{});

	// Bending strat 1
	bend_speed = max(2 - (vel/56), 0.2); // Make it easier to get fast bending
	if ((~bend_strat == 1) && (~bend_keys_1.includes(nn)), {
		switch(nn,
			~bend_keys_1[0], {~notes.do{arg synth; synth.set(\bend_final, -2); synth.set(\bend_speed, bend_speed)}},
			~bend_keys_1[1], {~notes.do{arg synth; synth.set(\bend_final, -1); synth.set(\bend_speed, bend_speed)}},
			~bend_keys_1[2], {~notes.do{arg synth; synth.set(\bend_final, 1); synth.set(\bend_speed, bend_speed)}},
			~bend_keys_1[3], {~notes.do{arg synth; synth.set(\bend_final, 2); synth.set(\bend_speed, bend_speed)}}
		)
	}, {});

	// Bending strat 2
	if ((~bend_strat == 2) && (~bend_keys_2.includes(nn)), {

		if (~initial_key == -1, {
			switch(nn,
				~bend_keys_2[0], {~initial_key = 0;},
				~bend_keys_2[1], {~initial_key = 1;},
				~bend_keys_2[2], {~initial_key = 2;},
				~bend_keys_2[3], {~initial_key = 3;},
				~bend_keys_2[4], {~initial_key = 4;})},
		{
			if ((~initial_key != -1) && (nn == ~bend_keys_2[~initial_key]), {~initial_key = -1}, {});
		});

		k = ~initial_key;
		switch(nn,
			~bend_keys_2[0], {~notes.do{arg synth; synth.set(\bend_final, ~bend_value_array_0[k]); synth.set(\bend_speed, bend_speed)}},
			~bend_keys_2[1], {~notes.do{arg synth; synth.set(\bend_final, ~bend_value_array_1[k]); synth.set(\bend_speed, bend_speed)}},
			~bend_keys_2[2], {~notes.do{arg synth; synth.set(\bend_final, ~bend_value_array_2[k]); synth.set(\bend_speed, bend_speed)}},
			~bend_keys_2[3], {~notes.do{arg synth; synth.set(\bend_final, ~bend_value_array_3[k]); synth.set(\bend_speed, bend_speed)}},
			~bend_keys_2[4], {~notes.do{arg synth; synth.set(\bend_final, ~bend_value_array_4[k]); synth.set(\bend_speed, bend_speed)}}
		)
	}, {});

	// Regular notes
	if (nn > ~bend_keys_2[4], {
		~notes[nn] = Synth.new(
			\tone,
			[
				\freq, nn.midicps,
				\amp, vel.linexp(1,127,0.01,0.3),
				\gate, 1,
				\bend_final, 0,
				\bend_speed, 0,
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

	if ((~bend_strat == 1) && (~bend_keys_1.includes(nn)), {
		switch(nn,
			~bend_keys_1[0], {~notes.do{arg synth; synth.set(\bend_final, 0)}},
			~bend_keys_1[1], {~notes.do{arg synth; synth.set(\bend_final, 0)}},
			~bend_keys_1[2], {~notes.do{arg synth; synth.set(\bend_final, 0)}},
			~bend_keys_1[3], {~notes.do{arg synth; synth.set(\bend_final, 0)}}
		)
	}, {});

	if ((~bend_strat == 2) && (nn > ~bend_keys_2[4]), {~initial_key = -1}, {});

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
