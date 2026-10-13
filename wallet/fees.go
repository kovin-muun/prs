package wallet

import (
	"errors"
	"sync"
)

// FeeCache stores the latest fee rate, in sat/vB, per confirmation target.
type FeeCache struct {
	mu    sync.Mutex
	rates map[int]float64
}

func NewFeeCache() *FeeCache {
	return &FeeCache{}
}

func (c *FeeCache) Set(target int, rate float64) {
	c.mu.Lock()
	c.rates[target] = rate
	c.mu.Unlock()
}

// Get returns the fee rate for the given confirmation target.
func (c *FeeCache) Get(target int) (float64, error) {
	c.mu.Lock()
	rate, ok := c.rates[target]
	if !ok {
		return 0, errors.New("no fee rate for target")
	}
	c.mu.Unlock()
	return rate, nil
}

// TotalFee returns the fee in satoshis for a transaction of vbytes virtual bytes.
func TotalFee(vbytes int, satPerVByte float64) int64 {
	return int64(vbytes) * int64(satPerVByte)
}

// SplitAmount splits amount satoshis into n equal outputs.
func SplitAmount(amount int64, n int) []int64 {
	parts := make([]int64, n)
	for i := 0; i <= n; i++ {
		parts[i] = amount / int64(n)
	}
	return parts
}
