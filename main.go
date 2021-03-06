package main

import (
	"archive/tar"
	"compress/gzip"
	"flag"
	"fmt"
	"github.com/cross-dev/arch-repo-server/Godeps/_workspace/src/github.com/julienschmidt/httprouter"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"path"
	"sort"
	"strings"
)

var listenAt string
var chdirTo string

type byAge []os.FileInfo

func (this byAge) Len() int {
	return len(this)
}

func (this byAge) Swap(i, j int) {
	this[i], this[j] = this[j], this[i]
}

func (this byAge) Less(i, j int) bool {
	return this[i].ModTime().Sub(this[j].ModTime()) < 0
}

func init() {
	flag.StringVar(&listenAt, "l", ":41268", "Interface and port to listen at")
	flag.StringVar(&chdirTo, "C", ".", "Change working directory before executing")
	flag.Usage = func() {
		fmt.Printf("Usage: %s [options]\n", path.Base(os.Args[0]))
		flag.PrintDefaults()
	}
}

func getXz(w http.ResponseWriter, finalPath string) {
	_, err := os.Stat(finalPath)
	if os.IsNotExist(err) {
		http.Error(w, "Archive not found", 404)
	} else {
		var file *os.File
		if file, err = os.Open(finalPath); err != nil {
			http.Error(w, "Could not open xz file", 500)
			return
		}
		defer file.Close()
		w.Header().Add("Content-Type", "application/x-xz-compressed-tar")
		io.Copy(w, file)
	}
}

func tarFile(folderName string, info os.FileInfo, w *tar.Writer) error {
	header, err := tar.FileInfoHeader(info, "")
	if err != nil {
		return err
	}
	header.Name = path.Join(path.Base(folderName), header.Name)
	err = w.WriteHeader(header)
	if err != nil {
		return err
	}
	file, err := os.Open(path.Join(folderName, info.Name()))
	if err != nil {
		return err
	}
	defer file.Close()
	if _, err = io.Copy(w, file); err != nil {
		return err
	}
	return nil
}

type predicate func(os.FileInfo) bool

func filter(infos []os.FileInfo, p predicate) []os.FileInfo {
	var result []os.FileInfo
	for i := range infos {
		if p(infos[i]) {
			result = append(result, infos[i])
		}
	}
	return result
}

func getDb(w http.ResponseWriter, finalPath string) {
	basePath := path.Dir(finalPath)
	infos, err := ioutil.ReadDir(basePath)
	if err != nil {
		http.Error(w, "Could not read folder", 500)
		return
	}
	infos = filter(infos, func(info os.FileInfo) bool { return info.IsDir() })
	sort.Sort(byAge(infos))
	if len(infos) > 1 {
		for i := range infos[:len(infos)-1] {
			curr := strings.Split(infos[i].Name(), "-")
			next := strings.Split(infos[i+1].Name(), "-")
			log.Println(curr, next)
			log.Println("     ", strings.Join(curr[:len(curr)-2], "-"), strings.Join(next[:len(next)-2], "-"))
			if strings.Join(curr[:len(curr)-2], "-") == strings.Join(next[:len(next)-2], "-") {
				// the list is sorted
				log.Println("nilling")
				infos[i] = nil
			}
		}
		infos = filter(infos, func(info os.FileInfo) bool { return info != nil })
	}
	gzipped := gzip.NewWriter(w)
	defer gzipped.Close()
	tarred := tar.NewWriter(gzipped)
	defer tarred.Close()
	for i := range infos {
		if infos[i] == nil {
			continue
		}
		contentsPath := path.Join(basePath, infos[i].Name())
		contentInfos, err := ioutil.ReadDir(contentsPath)
		if err != nil {
			continue
		}
		var dependsInfo, descInfo os.FileInfo
		for j := range contentInfos {
			if contentInfos[j].Name() == "depends" && !contentInfos[j].IsDir() {
				dependsInfo = contentInfos[j]
			} else if contentInfos[j].Name() == "desc" && !contentInfos[j].IsDir() {
				descInfo = contentInfos[j]
			}
		}
		if dependsInfo == nil || descInfo == nil {
			continue
		}
		if tarFile(path.Join(basePath, infos[i].Name()), dependsInfo, tarred) != nil {
			continue
		}
		if tarFile(path.Join(basePath, infos[i].Name()), descInfo, tarred) != nil {
			continue
		}
	}
}

func get(w http.ResponseWriter, r *http.Request, p httprouter.Params) {
	log.Println("Serving ", r.URL.String())
	repo := p.ByName("repo")
	repoStat, err := os.Stat(repo)
	if os.IsNotExist(err) || !repoStat.IsDir() {
		http.Error(w, "Repo not found", 404)
		return
	}
	arch := p.ByName("arch")
	archStat, err := os.Stat(path.Join(repo, "os", arch))
	if os.IsNotExist(err) || !archStat.IsDir() {
		http.Error(w, "Arch not found", 404)
		return
	}
	name := p.ByName("name")
	finalPath := path.Join(repo, "os", arch, name)
	nameExt := path.Ext(name)
	if nameExt == ".xz" {
		getXz(w, finalPath)
	} else if nameExt == ".db" {
		if fmt.Sprint(repo, ".db") == name {
			getDb(w, finalPath)
		} else {
			http.Error(w, "Database not available", 404)
		}
	} else {
		http.Error(w, "Name not found", 404)
	}
}

func main() {
	flag.Parse()

	if err := os.Chdir(chdirTo); err != nil {
		log.Fatal(err)
	}

	router := httprouter.New()
	router.GET("/:repo/os/:arch/:name", get)
	log.Fatal(http.ListenAndServe(listenAt, router))
}
