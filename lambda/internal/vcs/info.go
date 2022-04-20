package vcs

import (
	"runtime/debug"
	"strings"
	"time"
)

type Info struct {
	Type     string    `json:"type"`
	Short    string    `json:"short"`
	Long     string    `json:"long"`
	Time     time.Time `json:"time"`
	Modified bool      `json:"modified"`
}

func GetInfo() *Info {
	bi, ok := debug.ReadBuildInfo()
	if !ok {
		return nil
	}

	vcs := &Info{}

	for _, s := range bi.Settings {
		if s.Key == "vcs" {
			vcs.Type = s.Value
			continue
		}

		if strings.HasPrefix(s.Key, "vcs.") {
			if _, a, ok := strings.Cut(s.Key, "."); ok {
				switch a {
				case "revision":
					vcs.Long = s.Value
					vcs.Short = s.Value[:7]
				case "modified":
					vcs.Modified = s.Value == "true"
				case "time":
					vcs.Time, _ = time.Parse(time.RFC3339, s.Value)
				}
			}
		}
	}

	if vcs.Type == "" {
		return nil
	}

	return vcs
}
