import pickle
import numpy as np
from scipy.io import savemat

with open("RML2016.10a_dict_optimized.pkl", "rb") as f:
    data = pickle.load(f)

X = []
modulation = []
snr = []

for (mod, s), signals in data.items():
    X.append(signals)
    modulation.extend([mod] * len(signals))
    snr.extend([s] * len(signals))

X = np.concatenate(X, axis=0)

savemat(
    "RadioML2016_mid.mat",
    {
        "X": X.astype(np.float32),
        "modulation": np.array(modulation, dtype=object),
        "snr": np.array(snr)
    },
    do_compression=True
)

print("Conversion completed!")
print("Data shape:", X.shape)