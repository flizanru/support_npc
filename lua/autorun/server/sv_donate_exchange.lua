local DATABASE_HOST = "localhost" -- Хост базы данных
local DATABASE_PORT = 3306 -- Порт базы данных
local DATABASE_NAME = "your_database_name" -- Имя базы данных
local DATABASE_USERNAME = "your_username" -- Имя пользователя базы данных
local DATABASE_PASSWORD = "your_password" -- Пароль базы данных

local ExchangeDB = mysqloo.connect(DATABASE_HOST, DATABASE_USERNAME, DATABASE_PASSWORD, DATABASE_NAME, DATABASE_PORT)

function ExchangeDB:onConnected()
    print("[DONATE-EXCHANGES] Успешно подключено к базе данных.")
    CreateExchangeTable(ExchangeDB)
end

function ExchangeDB:onConnectionFailed(err)
    print("[DONATE-EXCHANGES] Ошибка подключения к базе данных:", err)
end

ExchangeDB:connect()

function CreateExchangeTable()
    local query = ExchangeDB:query([[
        CREATE TABLE IF NOT EXISTS flizan_exchanges (
            id INT AUTO_INCREMENT PRIMARY KEY,
            checkid VARCHAR(20) UNIQUE,
            name VARCHAR(255),
            steamid VARCHAR(20),
            steamid64 VARCHAR(20),
            date DATETIME,
            ip VARCHAR(15),
            donation_received INT,
            sellmoney INT,
            donateold_balance INT,
            donate2 INT
        )
    ]])

    function query:onSuccess()
        print("[DONATE-EXCHANGES] Таблица 'flizan_exchanges' успешно создана!")
    end

    function query:onError(err)
        print("[DONATE-EXCHANGES] Ошибка при создании таблицы 'flizan_exchanges':", err)
    end

    query:start()
end

CreateExchangeTable()

util.AddNetworkString("ExchangeInfo")
util.AddNetworkString("ExchangeStatus")
util.AddNetworkString("ExchangeDonateCurrency")
util.AddNetworkString("ConfirmExchange")
util.AddNetworkString("ExchangeCompleted")
util.AddNetworkString("ExchangeInfoDelayed")

-- Таблица с курсами обмена
local exchangeRates = {
    [1000000] = 1,
    [10000000] = 10,
    [20000000] = 30,
}

local function canExchangeDonateCurrency(ply, amount)
    return ply:getDarkRPVar("money") >= amount
end

local function performExchange(ply, amount)
    local exchangeRate = exchangeRates[amount]

    if exchangeRate and canExchangeDonateCurrency(ply, amount) then
        local checkid = GenerateUniqueCheckID()
        ply:addMoney(-amount)
        ply:AddIGSFunds(exchangeRate)

        net.Start("ExchangeCompleted")
        net.Send(ply)

        SaveExchangeInfo(checkid, ply, amount, exchangeRate)
        return true
    else
        return false
    end
end


local function canExchangeDonateCurrency(ply, amount)
    if not ply:canAfford(amount) then
        return false
    end

    local currentDate = os.date("%Y-%m-%d")
    local query = ExchangeDB:query("SELECT COUNT(*) as numExchanges FROM flizan_exchanges WHERE steamid = '" .. ply:SteamID() .. "' AND DATE(date) = '" .. currentDate .. "'")

    local maxExchangesPerDay = 5
    local numExchanges = 0

    function query:onSuccess(data)
        numExchanges = tonumber(data[1].numExchanges) or 0
    end

    function query:onError(err)
        print("[DONATE-EXCHANGES] Ошибка при проверке количества обменов за день:", err)
    end

    query:start()
    query:wait()

    if numExchanges >= maxExchangesPerDay then
        return false
    end

    return true
end

local exchangeInProgress = {}

net.Receive("ExchangeDonateCurrency", function(_, ply)
    if exchangeInProgress[ply] then return end  
    local amount = net.ReadInt(32)

    net.Start("ExchangeStatus")

    if canExchangeDonateCurrency(ply, amount) then
        net.WriteBool(true)
        net.Send(ply)

        net.Receive("ConfirmExchange", function(_, ply)
            exchangeInProgress[ply] = true 

            local confirm = net.ReadBool()

            if confirm then
                if performExchange(ply, amount) then
                    net.Start("ExchangeStatus")
                    net.WriteBool(true)
                    net.Send(ply)
                else
                    net.Start("ExchangeStatus")
                    net.WriteBool(false)
                    net.Send(ply)
                end

                exchangeInProgress[ply] = false 
            end
        end)
    else
        net.WriteBool(false)
        net.Send(ply)
    end
end)

net.Receive("ConfirmExchange", function(_, ply)
    local confirm = net.ReadBool()

    if confirm then
        net.Start("ExchangeCompleted")
        net.Send(ply)
    end
end)

function SaveExchangeInfo(checkid, ply, amount, exchangeRate)
    local name = ply:Nick()
    local steamid = ply:SteamID()
    local steamid64 = ply:SteamID64()
    local date = os.date("%Y-%m-%d %H:%M:%S")
    local ip = ply:IPAddress():match("([^:]+)")
    local donation_received = exchangeRate
    local sellmoney = amount
    local donateold_balance = ply:IGSFunds()
    local donate2 = ply:getDarkRPVar("money")

    local query = ExchangeDB:query(string.format([[
        INSERT INTO flizan_exchanges
        (checkid, name, steamid, steamid64, date, ip, donation_received, sellmoney, donateold_balance, donate2)
        VALUES
        ('%s', '%s', '%s', '%s', '%s', '%s', %d, %d, %d, %d)
    ]],
    checkid, name, steamid, steamid64, date, ip, donation_received, sellmoney, donateold_balance, donate2))

    function query:onSuccess()
        print("[DONATE-EXCHANGES] Информация об обмене успешно сохранена в базе данных! Чек: " .. checkid)

        local infoTable = {
            checkid = checkid,
        }

        net.Start("ExchangeInfo")
        net.WriteTable(infoTable)
        net.Send(ply)

        timer.Simple(3, function()
            net.Start("ExchangeInfoDelayed")
            net.WriteTable(infoTable)
            net.Send(ply)
        end)
    end

    function query:onError(err)
        print("[DONATE-EXCHANGES] Ошибка при сохранении информации об обмене в базе данных:", err)
    end

    query:start()
    query:wait()  
end

function GenerateUniqueCheckID()
    local checkid = "DN-" .. string.format("%06d", math.random(1, 999999))

    local query = ExchangeDB:query("SELECT checkid FROM flizan_exchanges WHERE checkid = '" .. checkid .. "'")

    local unique = true
    function query:onSuccess(data)
        if #data > 0 then
            unique = false
        end
    end

    function query:onError(err)
        print("[DONATE-EXCHANGES] Ошибка при проверке уникальности checkid:", err)
    end

    query:start()
    query:wait()

    if not unique then
        return GenerateUniqueCheckID() 
    end

    return checkid
end
