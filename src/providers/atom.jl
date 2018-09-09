using Logging
using JSON
using AssetRegistry
using Sockets
using Base64: stringmime


struct WebSockConnection <: WebIO.AbstractConnection
    sock
end

Base.isopen(p::WebSockConnection) = isopen(p.sock)

function Sockets.send(p::WebSockConnection, data)
    write(p.sock, sprint(io->JSON.print(io,data)))
end

const key = AssetRegistry.register(joinpath(@__DIR__, "..", "..", "assets"))

const port = Ref{Int}(8000)

function Base.show(io::IO, ::MIME"application/juno+plotpane", n::Union{Node, Scope, AbstractWidget})
    port[] = port[] + 1
    @async begin
        try
            server = listen(ip"127.0.0.1", port[])
            sock = accept(server)
            conn = WebSockConnection(sock)

            while isopen(sock)
                data = read(sock)
                @show data
                msg = JSON.parse(String(data))
                WebIO.dispatch(conn, msg)
            end
        catch e
            @show e
        end
    end
    # no clue how AssetRegistry works so just serve the files from disk
    print(io,
        """
        <!doctype html>
        <html>
          <head>
            <meta charset="UTF-8">
            <script> var port = $(port[])</script>
            <script src="file://$(joinpath(@__DIR__, "..", "..", "assets"))/webio/dist/bundle.js"></script>
            <script src="file://$(joinpath(@__DIR__, "..", "..", "assets"))/providers/atom_setup.js"></script>
          </head>
          <body>
            $(stringmime(MIME"text/html"(), n))
          </body>
        </html>
        """
    )
end

function WebIO.register_renderable(::Type{T}, ::Val{:atom}) where {T}
    eval(quote
        function Base.show(io::IO, m::MIME"application/juno+plotpane", x::$T)
            show(io, m, WebIO.render(x))
        end
    end)
end

WebIO.setup_provider(::Val{:atom}) = nothing # Mux setup has no side-effects
WebIO.setup(:atom)
