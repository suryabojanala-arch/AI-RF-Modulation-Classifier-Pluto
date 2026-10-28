This is our final project for Software Defined Communication Systems (23AID203) at Amrita.

Basically we trained a CNN in MATLAB to recognise what type of modulation a radio signal is using, just by looking at its I/Q samples. Then we tested it on real signals using an ADALM-Pluto SDR instead of only a dataset.

Modulations we used: AM-DSB, WBFM, BPSK, QPSK and QAM16

THIS HOW IT WORKS:-
First we trained the CNN on the RadioML 2016.10a dataset. Each input is a 2x128 frame (128 I values and 128 Q values).

After that we connected the Pluto. We put one antenna on TX and one on RX, around 2 cm apart, and sent each modulation over the air at 915 MHz. The received samples go into the same CNN.

The accuracy dropped a lot on real signals, so we recorded our own data with the Pluto (25,000 frames) and fine-tuned the model on it. We also made a live dashboard where you press 1-5 to change the modulation and it shows what the model predicts in real time.

We used a 70/15/15 split for training, validation and testing in both cases.

THE RESULTS WE GOT :
1.RadioML test set: 85.25%
2.Real Pluto signals before fine tuning: 74.1%
3.Real Pluto signals after fine tuning: 96.7% , tested on a new recording it never saw

AM-DSB was the worst one at first (only around 4%). Our receiver removes the DC part of the signal, which also removes the AM carrier, so it looked different from the dataset. After fine tuning it went up to 91%.

#team
B.Surya charan tej en.al
