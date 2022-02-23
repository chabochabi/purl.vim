
if exists("g:loaded_test")
  finish
endif
let g:loaded_test= 1
let s:save_cpo = &cpo
set cpo&vim

let s:purl = {}

" python stuff
let s:python_header = "#!/usr/bin/python"
let s:python_imports = ["requests"]

function! s:write_python_file()
    execute "normal! i" . s:python_header . "\n\n"
    for i in s:python_imports
        execute "normal! i" . "import " . i . "\n"
    endfor
    execute "normal! i" . "\n"

    " write headers
    execute "normal! i" . "headers = {\n"
    for key in keys(s:purl.headers)
        execute "normal! i" . "\t'" . key . "': '". s:purl.headers[key] . "'," . "\n"
    endfor
    execute "normal! i" . "}\n\n"

    " write data 
    execute "normal! i" . "data = {\n"
    for key in keys(s:purl.data)
        execute "normal! i" . "\t'" . key . "': '". s:purl.data[key] . "'," . "\n"
    endfor
    execute "normal! i" . "}\n\n"

    " write request
    execute "normal! i" . "if data:\n"
    execute "normal! i" . "\tresp = requests." . tolower(s:purl.method) . "('" . s:purl.url . "', headers=headers, data=data)\n"
    execute "normal! i" . "else:\n"
    execute "normal! i" . "\tresp = requests." . tolower(s:purl.method) . "('" . s:purl.url . "', headers=headers)\n"
    execute "normal! i" . "print(resp.status_code)\n"
    execute "normal! i" . "print(resp.text)\n"
endfunction

function! s:find_headers(curl)
    let has_headers = v:true
    let header_idx = match(a:curl, "-H")
    let headers = {}
    while has_headers
        let header = matchstr(a:curl, '\c-H \([''"]\)\zs.\{-}\ze\1', header_idx)
        let h_split = split(header, ": ")
        let headers[h_split[0]] = h_split[1]
        let header_idx = match(a:curl, "-H", header_idx+2)
        if header_idx < 0
            let has_headers = v:false 
        endif
    endwhile
    return headers 
endfunction

function! s:find_method(curl)
    let method = matchstr(a:curl, '\c-X \([''"]\)\zs.\{-}\ze\1')
    if empty(method)
        let data = match(a:curl, '\c --data \| -d \| --data-raw')
        if data < 0
            let method = "GET"
        else
            let method = "POST"
        endif
    endif
    return method 
endfunction

function! s:find_data(curl)
    let data = matchstr(a:curl, '\c--data \| -d \| --data-raw \([''"]\)\zs.\{-}\ze\1')
    let split_data = split(data, "&")
    let data_dict = {}
    for d in split_data
        let pair = split(d, "=")
        if len(pair) == 2
            let data_dict[pair[0]] = pair[1]
        else
            let data_dict[pair[0]] = ""
        endif
    endfor
    return data_dict 
endfunction

function! s:find_url(curl)
    return matchstr(a:curl, '\ccurl \([''"]\)\zs.\{-}\ze\1')
endfunction

function! s:delete_curl()
    let lines = line("$")
    while lines > 0
        d
        let lines -= 1
    endwhile
endfunction

function! Purl(language) 
    let lines = line("$")
    let curl_cmd = ""

    " hacky way to transform multiline curl command to a single liner
    if lines > 1
        for l in range(0,lines)
            let curl_cmd = curl_cmd . substitute(getline(l), "\\", "", "g")
        endfor
    endif
    let curl_cmd = substitute(curl_cmd, "\n$", "", "")
    let s:purl.url = s:find_url(curl_cmd)
    let s:purl.headers = s:find_headers(curl_cmd)
    let s:purl.method = s:find_method(curl_cmd)
    let s:purl.data = s:find_data(curl_cmd)

    let deleted = s:delete_curl()
    if a:language == "python"
        let done = s:write_python_file()
    endif
endfunction

if !exists(":Purl")
  command -nargs=1 Purl call Purl(<q-args>)
endif

let &cpo = s:save_cpo
unlet s:save_cpo
