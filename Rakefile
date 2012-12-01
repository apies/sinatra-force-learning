task :make_certs do
	openssl "genrsa -des3 -out server.orig.key 2048"
	openssl "rsa -in server.orig.key -out server.key"
	openssl "req -new -key server.key -out server.csr"
end