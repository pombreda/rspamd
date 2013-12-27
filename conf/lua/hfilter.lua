--
-- Copyright (c) 2013, Alexey Savelyev
-- E-mail: info@homeweb.ru
-- WWW: http://homeweb.ru
--

--Rating for checks_hellohost and checks_hello: 5 - very hard, 4 - hard, 3 - meduim, 2 - low, 1 - very low
local checks_hellohost = {
['[.-]dynamic[.-]'] = 5, ['dynamic[.-][0-9]'] = 5, ['[0-9][.-]?dynamic'] = 5, 
['[.-]dyn[.-]'] = 5, ['dyn[.-][0-9]'] = 5, ['[0-9][.-]?dyn'] = 5, 
['[.-]clients?[.-]'] = 5, ['clients?[.-][0-9]'] = 5, ['[0-9][.-]?clients?'] = 5, 
['[.-]dynip[.-]'] = 5, ['dynip[.-][0-9]'] = 5, ['[0-9][.-]?dynip'] = 5, 
['[.-]broadband[.-]'] = 5, ['broadband[.-][0-9]'] = 5, ['[0-9][.-]?broadband'] = 5, 
['[.-]broad[.-]'] = 5, ['broad[.-][0-9]'] = 5, ['[0-9][.-]?broad'] = 5, 
['[.-]bredband[.-]'] = 5, ['bredband[.-][0-9]'] = 5, ['[0-9][.-]?bredband'] = 5, 
['[.-]nat[.-]'] = 5, ['nat[.-][0-9]'] = 5, ['[0-9][.-]?nat'] = 5, 
['[.-]pptp[.-]'] = 5, ['pptp[.-][0-9]'] = 5, ['[0-9][.-]?pptp'] = 5, 
['[.-]pppoe[.-]'] = 5, ['pppoe[.-][0-9]'] = 5, ['[0-9][.-]?pppoe'] = 5, 
['[.-]ppp[.-]'] = 5, ['ppp[.-][0-9]'] = 5, ['[0-9][.-]?ppp'] = 5, 
['[.-][a|x]?dsl[.-]'] = 4, ['[a|x]?dsl[.-]?[0-9]'] = 4, ['[0-9][.-]?[a|x]?dsl'] = 4, 
['[.-][a|x]?dsl-dynamic[.-]'] = 5, ['[a|x]?dsl-dynamic[.-]?[0-9]'] = 5, ['[0-9][.-]?[a|x]?dsl-dynamic'] = 5, 
['[.-][a|x]?dsl-line[.-]'] = 4, ['[a|x]?dsl-line[.-]?[0-9]'] = 4, ['[0-9][.-]?[a|x]?dsl-line'] = 4, 
['[.-]dhcp[.-]'] = 5, ['dhcp[.-][0-9]'] = 5, ['[0-9][.-]?dhcp'] = 5, 
['[.-]catv[.-]'] = 5, ['catv[.-][0-9]'] = 5, ['[0-9][.-]?catv'] = 5, 
['[.-]wifi[.-]'] = 5, ['wifi[.-][0-9]'] = 5, ['[0-9][.-]?wifi'] = 5, 
['[.-]unused-addr[.-]'] = 3, ['unused-addr[.-][0-9]'] = 3, ['[0-9][.-]?unused-addr'] = 3, 
['[.-]dial-?up[.-]'] = 5, ['dial-?up[.-][0-9]'] = 5, ['[0-9][.-]?dial-?up'] = 5, 
['[.-]gprs[.-]'] = 5, ['gprs[.-][0-9]'] = 5, ['[0-9][.-]?gprs'] = 5, 
['[.-]cdma[.-]'] = 5, ['cdma[.-][0-9]'] = 5, ['[0-9][.-]?cdma'] = 5, 
['[.-]homeuser[.-]'] = 5, ['homeuser[.-][0-9]'] = 5, ['[0-9][.-]?homeuser'] = 5, 
['[.-]in-?addr[.-]'] = 4, ['in-?addr[.-][0-9]'] = 4, ['[0-9][.-]?in-?addr'] = 4, 
['[.-]pool[.-]'] = 4, ['pool[.-][0-9]'] = 4, ['[0-9][.-]?pool'] = 4, 
['[.-]cable[.-]'] = 3, ['cable[.-][0-9]'] = 3, ['[0-9][.-]?cable'] = 3,
['[.-]host[.-]'] = 2, ['host[.-][0-9]'] = 2, ['[0-9][.-]?host'] = 2,
['[.-]customers[.-]'] = 1, ['customers[.-][0-9]'] = 1, ['[0-9][.-]?customers'] = 1
}

local checks_hello = {
['localhost$'] = 5, ['\\.hfilter\\.ru'] = 5, ['^\\[*84\\.47\\.176\\.(70|71)'] = 5, ['^\\[*81\\.26\\.148\\.(66|67|68|69|70|71|72|73|74|75|76|77|79)'] = 5,
['^(dsl)?(device|speedtouch)\\.lan$'] = 5,
['\\.(lan|local|home|localdomain|intra|in-addr.arpa|priv|online|user|veloxzon)$'] = 5,
['^\\[*127\\.'] = 5, ['^\\[*10\\.'] = 5, ['^\\[*172\\.16\\.'] = 5, ['^\\[*192\\.168\\.'] = 5,
--bareip
['^\\[*\\d+[x.-]\\d+[x.-]\\d+[x.-]\\d+\\]*$'] = 4
}

local function trim1(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function check_regexp(str, regexp_text)
    local re = regexp.get_cached(regexp_text)
    if not re then re = regexp.create(regexp_text, 'i') end
    if re:match(str) then return true end
return false
end

local function split(str, delim, maxNb)
    -- Eliminate bad cases...
    if string.find(str, delim) == nil then
        return { str }
    end
    if maxNb == nil or maxNb < 1 then
        maxNb = 0    -- No limit
    end
    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gmatch(str, pat) do
        nb = nb + 1
        result[nb] = part
        lastPos = pos
        if nb == maxNb then break end
    end
    -- Handle the last field
    if nb ~= maxNb then
        result[nb + 1] = string.sub(str, lastPos)
    end
    return result
end

local function check_fqdn(domain)
    if check_regexp(domain, '(?=^.{4,255}$)(^((?!-)[a-zA-Z0-9-]{1,63}(?<!-)\\.)+[a-zA-Z]{2,63}$)') then
        return true
    end
return false
end

-- host: host for check
-- symbol_suffix: suffix for symbol
-- eq_ip: ip for comparing or empty string
-- eq_host: host for comparing or empty string
local function check_host(task, host, symbol_suffix, eq_ip, eq_host)

    local function check_host_cb_mx_a(resolver, to_resolve, results, err)
        task:inc_dns_req()
        if not results then
            task:insert_result('HFILTER_' .. symbol_suffix .. '_NORESOLVE_MX', 1.0)
        end
    end
    local function check_host_cb_mx(resolver, to_resolve, results, err)
        task:inc_dns_req()
        if not results then
            task:insert_result('HFILTER_' .. symbol_suffix .. '_NORES_A_OR_MX', 1.0)
        else
            for _,mx in pairs(results) do
                if mx['name'] then
                    task:get_resolver():resolve_a(task:get_session(), task:get_mempool(), mx['name'], check_host_cb_mx_a)
                end
            end
        end
    end
    local function check_host_cb_a(resolver, to_resolve, results, err)
        task:inc_dns_req()
        
        if not results then
            task:get_resolver():resolve_mx(task:get_session(), task:get_mempool(), host, check_host_cb_mx)
        elseif eq_ip ~= '' then
            for _,result in pairs(results) do 
                if result:to_string() == eq_ip then
                    return true
                end
            end
            task:insert_result('HFILTER_' .. symbol_suffix .. '_IP_A', 1.0)
        end
    end

    if host then
        host = string.lower(host)
    else
        return false
    end
    if eq_host then
        eq_host = string.lower(eq_host)
    else
        eq_host = ''
    end

    if check_fqdn(host) then
        if eq_host == '' or eq_host ~= host then
            task:get_resolver():resolve_a(task:get_session(), task:get_mempool(), host, check_host_cb_a)
        end
    else
        task:insert_result('HFILTER_' .. symbol_suffix .. '_NOT_FQDN', 1.0)
    end
    
return true
end

--
local function hfilter(task)
    local recvh = task:get_received_headers()
    
    if table.maxn(recvh) == 0 then 
        return false
    end
    
    --IP--
    local ip = false
    local rip = task:get_from_ip()
        if rip then
            ip = rip:to_string()
            if ip and ip == '0.0.0.0' then
                ip = false
            end
        end
    
    --HOSTNAME--
    local r = recvh[1]
    local hostname = false
    local hostname_lower = false
        if r['real_hostname'] and ( r['real_hostname'] ~= 'unknown' or not check_regexp(r['real_hostname'], '^\\d+\\.\\d+\\.\\d+\\.\\d+$') ) then
            hostname = r['real_hostname']
            hostname_lower = string.lower(hostname)
        end
    
    --HELO--
    local helo = task:get_helo()
    local helo_lower = false
        if helo then
            helo_lower = string.lower(helo)
        else
            helo = false
            helo_lower = false
        end
    
    --MESSAGE--
    local message = task:get_message()
    
    --RULES--RULES--RULES--

    -- Check's HELO
    local checks_hello_found = false
    if helo    then
        -- Regexp check HELO
        for regexp,weight in pairs(checks_hello) do
            if check_regexp(helo_lower, regexp) then
                task:insert_result('HFILTER_HELO_' .. weight, 1.0)
                checks_hello_found = true
                break
            end
        end
        if not checks_hello_found then
            for regexp,weight in pairs(checks_hellohost) do
                if check_regexp(helo_lower, regexp) then
                    task:insert_result('HFILTER_HELO_' .. weight, 1.0)
                    checks_hello_found = true
                    break
                end
            end
        end
        
        --FQDN check HELO
        check_host(task, helo, 'HELO', ip, hostname)
    end
    
    --
    local function check_hostname(hostname_res)
        -- Check regexp HOSTNAME
        for regexp,weight in pairs(checks_hellohost) do
            if check_regexp(hostname_res, regexp) then
                task:insert_result('HFILTER_HOSTNAME_' .. weight, 1.0)
                break
            end
        end
    end
    local function hfilter_hostname_ptr(resolver, to_resolve, results, err)
        task:inc_dns_req()
        if results then
            check_hostname(results[1])
        end
    end
    
    -- Check's HOSTNAME
    if hostname then
        if not checks_hello_found then
            check_hostname(hostname)
        end
    else
        task:insert_result('HFILTER_HOSTNAME_NOPTR', 1.00)
        if not checks_hello_found then
            task:get_resolver():resolve_ptr(task:get_session(), task:get_mempool(), ip, hfilter_hostname_ptr)
        end
    end

    -- MAILFROM checks --
    local from = task:get_from()
    if from then
        --FROM host check
        for _,fr in ipairs(from) do
            local fr_split = split(fr['addr'], '@', 0)
            if table.maxn(fr_split) == 2 then
                check_host(task, fr_split[2], 'FROMHOST', '', '')
            end
        end
    end
    
    --Message ID host check
    local message_id = task:get_message_id()
    if message_id then
        local mid_split = split(message_id, '@', 0)
        if table.maxn(mid_split) == 2 and not string.find(mid_split[2], "local") then
            if not check_fqdn(mid_split[2]) then
                task:insert_result('HFILTER_MID_NOT_FQDN', 1.00)
            end
        end
    end
    
    -- Links checks
    local parts = task:get_text_parts()
    if parts then
        --One text part--
        if table.maxn(parts) > 0 and parts[1]:get_content() then
            local part_text = trim1(parts[1]:get_content())
            local total_part_len = string.len(part_text)
            if total_part_len > 0 then
                local urls = task:get_urls()
                if urls then
                    local total_url_len = 0
                    for _,url in ipairs(urls) do
                        total_url_len = total_url_len + string.len(url:get_text())
                    end
                    if total_url_len > 0 then
                        if total_url_len + 7 > total_part_len then
                            task:insert_result('HFILTER_URL_ONLY', 1.00)
                        else
                            if not string.find(part_text, "\n") then
                                task:insert_result('HFILTER_URL_ONELINE', 1.00)
                            end
                        end
                    end
                end
            end
        end
    end
    
    return false
end

rspamd_config:register_symbols(hfilter, 1.0, 
"HFILTER_HELO_1", "HFILTER_HELO_2", "HFILTER_HELO_3", "HFILTER_HELO_4", "HFILTER_HELO_5", 
"HFILTER_HOSTNAME_1", "HFILTER_HOSTNAME_2", "HFILTER_HOSTNAME_3", "HFILTER_HOSTNAME_4", "HFILTER_HOSTNAME_5", 
"HFILTER_HELO_NORESOLVE_MX", "HFILTER_HELO_NORES_A_OR_MX", "HFILTER_HELO_IP_A", "HFILTER_HELO_NOT_FQDN", 
"HFILTER_FROMHOST_NORESOLVE_MX", "HFILTER_FROMHOST_NORES_A_OR_MX", "HFILTER_FROMHOST_NOT_FQDN",  
"HFILTER_MID_NOT_FQDN",
"HFILTER_HOSTNAME_NOPTR",
"HFILTER_URL_ONLY", "HFILTER_URL_ONELINE");