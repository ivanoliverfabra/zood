local function a(b,c)if b=="array"then if type(c)~="table"then return false end;for d,e in ipairs(c)do if type(d)~="number"then return false end end;return true end;return type(c)==b end;local function f(g,h)h=h or 1;error(g,h)end;local function i(j,c,k)if not j.message then return k end;if type(j.message)=="function"then return j.message(c)end;if string.find(j.message,"%%s")then return string.format(j.message,c)end;return tostring(j.message)end;local function l(m)local n={}for o,p in pairs(m)do if type(p)=="function"then n[o]=nil elseif type(p)=="table"then if next(p)~=nil then n[o]=l(p)end else n[o]=p end end;return n end;local function q(r,c)if r.type=="table"and r.fields then local s={}for t,u in pairs(r.fields)do if c[t]~=nil then s[t]=q(u,c[t])elseif u.default~=nil then s[t]=u.default end end;return s elseif r.type=="array"then local s={}for d,v in ipairs(c)do s[d]=q(r.fields,v)end;return s elseif r.type=="union"then for e,w in ipairs(r.fields)do local x,y=w:safeParse(c)if x then return y end end;return c else return c end end;local z={}local A={}A.__index=A;function A.new(type,B,C,k,D,E,error)local r=setmetatable({},A)r.type=type or"unknown"r.fields=B or{}r.optional=C or false;r.default=k;r.validate=D;r.transform=E or function(c)return q(r,c)end;r.error=error or"Expected value of type '"..type.."', but got '%s' instead."r.min=nil;r.max=nil;r.length=nil;r.email=nil;r.url=nil;r.pattern=nil;r.positive=nil;r.negative=nil;return r end;function A:parse(c)local x,y=self:safeParse(c)if not x then f("Errors:\n"..table.concat(y,"\n"),3)end;return y end;function A:safeParse(c)local F={}if c==nil then if self.optional then return true,self.default else table.insert(F,string.format(self.error,"nil"))return false,F end end;local s;if self.type=="table"and self.fields then s={}for t,r in pairs(self.fields)do if c[t]~=nil then s[t]=c[t]elseif r.default~=nil then s[t]=r.default end end else s=c end;if self.transform then s=self.transform(s)end;if not self.validate and not a(self.type,s)then table.insert(F,string.format(self.error,type(s)))return false,F end;if self.validate then local x,G=self.validate(s)if not x then if a("table",G)then for e,H in ipairs(G)do table.insert(F,H)end else table.insert(F,G or string.format(self.error,type(s)))end end end;if self.type=="table"and self.fields then for t,r in pairs(self.fields)do if s[t]~=nil then local x,I=r:safeParse(s[t])if x then s[t]=I else if a("table",I)then for e,H in ipairs(I)do table.insert(F,H)end else table.insert(F,I)end end end end end;if#F>0 then return false,F else return true,s end end;function A:nullable()self.optional=true;local J=self.validate;self.validate=function(c)if c==nil then return true end;return J(c)end;return self end;function A:default(K)self.default=K;self.optional=true;if K~=nil then local L=self.validate(K)if not L then f("Default value is invalid. Expected "..self.type..", but got '"..type(K).."' instead.",3)end end;local J=self.validate;self.validate=function(c)if c==nil then return true end;return J(c)end;return self end;function A:validate(M)self.validate=M;return self end;function A:error(g)self.error=g;return self end;function A:min(K,j)if not j then j={}end;self.validate=self.validate or function(c)return true end;local J=self.validate;self.validate=function(c)local x,G=J(c)if not x then return false,G end;if a("number",c)and c<K then return false,i(j,c,"Value must be at least "..K..", got "..c)elseif a("string",c)and#c<K then return false,i(j,#c,"Length must be at least "..K..", got "..#c)elseif a("array",c)and#c<K then return false,i(j,#c,"Length must be at least "..K..", got "..#c)end;return true end;self.min=K;return self end;function A:max(K,j)if not j then j={}end;self.validate=self.validate or function(c)return true end;local J=self.validate;self.validate=function(c)local x,G=J(c)if not x then return false,G end;local N,O,P=a("number",c),a("string",c),a("array",c)if not N and not O and not P then return false,"Expected number, string, or array, got "..type(c)end;if N and c>K then return false,i(j,c,"Value must be at most "..K..", got "..c)elseif O and#c>K then return false,i(j,#c,"Length must be at most "..K..", got "..#c)elseif P and#c>K then return false,i(j,#c,"Length must be at most "..K..", got "..#c)end;return true end;self.max=K;return self end;function A:positive(j)if not j then j={}end;local J=self.validate or function(c)return true end;self.validate=function(c)local x,G=J(c)if not x then return false,G end;if not a("number",c)then return false,"Expected number, got "..type(c)end;if c<=0 then return false,i(j,c,"Value must be positive, got "..c)end;return true end;self.positive=true;return self end;function A:negative(j)if not j then j={}end;local J=self.validate or function(c)return true end;self.validate=function(c)local x,G=J(c)if not x then return false,G end;if not a("number",c)then return false,"Expected number, got "..type(c)end;if c>=0 then return false,i(j,c,"Value must be negative, got "..c)end;return true end;self.negative=true;return self end;function A:length(Q,j)if not j then j={}end;self.validate=self.validate or function(c)return true end;local J=self.validate;self.validate=function(c)local x,G=J(c)if not x then return false,G end;local R;if a("string",c)or a("array",c)then R=#c else return false,"Expected string or array, got "..type(c)end;if R~=Q then return false,i(j,R,"Length must be exactly "..Q..", got "..R)end;return true end;self.length=Q;return self end;function A:email(j)if not j then j={}end;local J=self.validate or function(c)return true end;self.validate=function(c)local x,G=J(c)if not x then return false,G end;if not a("string",c)then return false,"Expected string, got "..type(c)end;local S="^[%w%.%%%+%-]+@[%w%.%-]+%.[a-zA-Z]+$"if not string.match(c,S)then return false,i(j,c,"Value must be a valid email address, got "..c)end;return true end;self.email=true;return self end;function A:url(j)if not j then j={}end;local J=self.validate or function(c)return true end;self.validate=function(c)local x,G=J(c)if not x then return false,G end;if not a("string",c)then return false,"Expected string, got "..type(c)end;local S="^https?://[%w%.%-]+%.[a-zA-Z]+$"if not string.match(c,S)then return false,i(j,c,"Value must be a valid URL, got "..c)end;return true end;self.url=true;return self end;function A:pattern(S,j)if not j then j={}end;local J=self.validate or function(c)return true end;self.validate=function(c)local x,G=J(c)if not x then return false,G end;if not a("string",c)then return false,"Expected string, got "..type(c)end;if not string.match(c,S)then return false,i(j,c,"Value must match pattern '"..S.."', got "..c)end;return true end;self.pattern=S;return self end;function A:enum(T,j)if not j then j={}end;local J=self.validate or function(c)return true end;self.validate=function(c)local x,G=J(c)if not x then return false,G end;for e,K in ipairs(T)do if c==K then return true end end;return false,i(j,c,"Value must be one of "..table.concat(T,", ")..", got "..c)end;self.fields=T;return self end;function A:trim(j)local U=self.transform or function(c)return c end;self.transform=function(c)c=U(c)if type(c)=="string"then return string.match(c,"^%s*(.-)%s*$")end;return c end;return self end;function A:lower(j)local U=self.transform or function(c)return c end;self.transform=function(c)c=U(c)if type(c)=="string"then return string.lower(c)end;return c end;return self end;function A:upper(j)local U=self.transform or function(c)return c end;self.transform=function(c)c=U(c)if type(c)=="string"then return string.upper(c)end;return c end;return self end;function A:between(V,W,j)if not j then j={}end;local J=self.validate or function(c)return true end;self.validate=function(c)local x,G=J(c)if not x then return false,G end;local K;if type(c)=="number"then K=c elseif type(c)=="string"then K=#c else return false,"Expected number or string, got "..type(c)end;if K<V or K>W then return false,i(j,K,"Value must be between "..V.." and "..W..", got "..K)end;return true end;self.min=V;self.max=W;return self end;function A:custom(M,j)local J=self.validate or function(c)return true end;self.validate=function(c)local x,G=J(c)if not x then return false,G end;return M(c)end;return self end;function z.string(j)if not j then j={}end;return A.new("string"):validate(function(c)if not a("string",c)then return false,i(j,c,"Expected string, got "..type(c))end;return true end)end;function z.number(j)if not j then j={}end;return A.new("number"):validate(function(c)if not a("number",c)then return false,i(j,c,"Expected number, got "..type(c))end;return true end)end;function z.boolean(j)if not j then j={}end;return A.new("boolean"):validate(function(c)if not a("boolean",c)then return false,i(j,c,"Expected boolean, got "..type(c))end;return true end)end;function z.table(B,j)return A.new("table",B):validate(function(c)local F={}if not a("table",c)then table.insert(F,"Expected table, got "..type(c))return false,F end;for t,r in pairs(B)do local x,G=r:safeParse(c[t])if not x then if type(G)=="table"then for e,H in ipairs(G)do table.insert(F,"Field '"..t.."': "..H)end else table.insert(F,"Field '"..t.."': "..G)end end end;if#F>0 then return false,F else return true end end)end;function z.array(X,j)return A.new("array",X):validate(function(c)local F={}if not a("table",c)then table.insert(F,"Expected array, got "..type(c))return false,F end;for d,v in ipairs(c)do local x,G=X:safeParse(v)if not x then if type(G)=="table"then for e,H in ipairs(G)do table.insert(F,"Element "..d..": "..H)end else table.insert(F,"Element "..d..": "..G)end end end;if#F>0 then return false,F else return true end end)end;function z.custom(Y)return A.new("custom"):validate(Y)end;function z.union(Z,j)if not j then j={}end;return A.new("union",Z):validate(function(c)local F={}for d,r in ipairs(Z)do local x,y=r:safeParse(c)if x then return true,y else table.insert(F,"Option "..d..": "..table.concat(y,", "))end end;return false,i(j,c,table.concat(F,"\n"))end)end;function z.toTable(r)r=l(r)local function _(a0)if getmetatable(a0)==A then local a1={type=a0.type}if a0.optional then a1.optional=true end;if a0.default~=nil then a1.default=a0.default end;if a0.error then a1.error=a0.error end;if a0.type=="table"and a0.fields then a1.fields={}for t,u in pairs(a0.fields)do a1.fields[t]=_(u)end elseif a0.type=="array"then a1.element=_(a0.fields)elseif a0.type=="enum"then a1.values=a0.fields elseif a0.type=="union"then a1.options={}for d,a2 in ipairs(a0.fields)do a1.options[d]=_(a2)end end;return a1 else return a0 end end;return _(r)end;function z.toJSON(r)return textutils.serializeJSON(z.toTable(r))end;function z.toFile(r,a3,type)if type~="json"and type~="lua"then f("Invalid file type: "..type)end;if not a3 then f("File name is required")end;local a4=fs.combine(shell.dir(),a3 .."."..type)local a5=io.open(a4,"w")if not a5 then f("Could not open file for writing: "..a4)end;if type=="json"then a5:write(z.toJSON(r))elseif type=="lua"then a5:write("return "..textutils.serialize(z.toTable(r)))else f("Unsupported file type: "..type)end;a5:close()end;return z