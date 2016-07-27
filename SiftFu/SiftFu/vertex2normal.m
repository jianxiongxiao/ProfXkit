function Nmap = vertex2normal(Vmap)

Nmap = cross((Vmap(2:end,1:end-1,1:3) - Vmap(1:end-1,1:end-1,1:3)),(Vmap(1:end-1,2:end,1:3) - Vmap(1:end-1,1:end-1,1:3)),3);

Len = sqrt(sum(Nmap.^2,3));
Nmap = Nmap ./ repmat(Len,[1,1,3]);

Nmap = Nmap .* double(repmat((Vmap(1:end-1,1:end-1,4)~=0) & (Vmap(2:end,1:end-1,4)~=0) & (Vmap(1:end-1,2:end,4)~=0),[1,1,3]));

Nmap(end+1,end+1,1) = 0;


