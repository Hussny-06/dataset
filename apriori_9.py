from itertools import combinations

def ordered_combinations(set_of_transactions, length_of_combination):
    return list(combinations(set_of_transactions, length_of_combination))

# Minimum support
minimum_support = 2
no_of_transactions = int(input('Enter number of transactions: '))

transactions = []
item_set = set()

print('Enter items bought in each transaction (space-separated): ')
for i in range(no_of_transactions):
    transaction = list(map(int, input(f'Transaction {i+1}: ').split()))
    transactions.append(transaction)
    item_set.update(transaction)

print(f'\nTransactions: {transactions}')
print(f'Minimum Support Count: {minimum_support}')
print(f'Item set (C1): {item_set}')

count = {}

# Generate combinations and count support
for c in range(2, len(item_set) + 1):
    candidate_item_set = ordered_combinations(item_set, c)
    print(f'\nC{c}: {candidate_item_set}')

    for candidate in candidate_item_set:
        for transaction in transactions:
            if set(candidate).issubset(transaction):
                count[candidate] = count.get(candidate, 0) + 1

# Filter frequent item sets
frequent_item_sets = [itemset for itemset, cnt in count.items() if cnt >= minimum_support]
print(f'\nFrequent Item Sets: {frequent_item_sets}')