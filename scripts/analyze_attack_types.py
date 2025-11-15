"""Analyze attack types in the dataset"""
import pandas as pd

df = pd.read_csv('../data/cleaned_cicddos2019_sample.csv', nrows=10000)

print("Label values:", sorted(df[' Label'].unique()))
print("\nProtocol values:", sorted(df[' Protocol'].unique()) if ' Protocol' in df.columns else "Protocol column not found")

if ' Protocol' in df.columns:
    print("\nProtocol distribution by label:")
    print(df.groupby([' Label', ' Protocol']).size())
    
    print("\n\nMost common label-protocol combinations:")
    print(df.groupby([' Label', ' Protocol']).size().sort_values(ascending=False).head(20))

